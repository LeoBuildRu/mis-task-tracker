# MIS Task Tracker API

API трекера задач для медицинской информационной системы (МИС). Тестовое задание на позицию Ruby on Rails разработчика (junior+).

## TL;DR

```bash
git clone <repo>
cd mis-task-tracker
cp .env.example .env
docker compose up --build
# → Web UI:     http://localhost:3000          (мокап-стайл, для ручной проверки)
# → Swagger UI: http://localhost:3000/api-docs (интерактивная документация)
# → API base:   http://localhost:3000/api/v1
```

При первом запуске контейнер сам выполнит `db:prepare` (создание БД + миграции) и `db:seed` (создание трёх обязательных системных тегов).

## Стек

- Ruby 3.4.3
- Rails 7.2 (API-only)
- PostgreSQL 16
- RSpec + FactoryBot
- rswag (Swagger UI + статичный `swagger/v1/swagger.yaml`)

## Запуск

### Через Docker (рекомендуемый способ)

Минимальный путь:

```bash
cp .env.example .env
docker compose up --build
```

Полезные команды внутри контейнера:

```bash
docker compose exec web bundle exec rails db:prepare
docker compose exec web bundle exec rails db:seed
docker compose exec web bundle exec rspec
docker compose exec web bundle exec rails console
```

### Локально (без Docker)

Понадобятся Ruby 3.4.3, PostgreSQL 16+ и bundler.

```bash
bundle install
cp .env.example .env  # отредактируйте под локальный Postgres
bin/rails db:prepare
bin/rails db:seed
bin/rails server
```

## Web UI (для ручной проверки)

По адресу `http://localhost:3000/` отдаётся одностраничный демо-интерфейс ([public/index.html](public/index.html)) — vanilla JS, без сборки. Сделан по мотивам мокапа из ТЗ:

- Сайдбар «МИС» (только пункт «Задачи» активный)
- Форма «Параметры задачи» + «Настройки повторяемости» — поддерживает все 5 типов повтора
- Список задач на выбранное окно с фильтрами (даты, статус)
- Кнопки на каждом дне периодической задачи: «Выполнено» / «Отменить день» / «Удалить серию» — это и есть тестирование изолированного состояния экземпляра и бонусной задачи из ТЗ
- Управление пользовательскими тегами + защищённые системные

Это вспомогательный инструмент, а не часть результата ТЗ. Деливерабл — API; UI просто помогает «потыкать» его в браузере без curl/Postman.

## API

База: `http://localhost:3000/api/v1`. Swagger UI: `/api-docs`.

| Endpoint | Метод | Назначение |
|---|---|---|
| `/tasks?from=...&to=...&status=...&tag_ids[]=...` | GET | Список задач в окне дат (одноразовые + развёрнутые повторы) |
| `/tasks` | POST | Создать задачу (одноразовую или с правилом повтора) |
| `/tasks/:id` | GET | Получить задачу-серию |
| `/tasks/:id` | PATCH | Обновить серию |
| `/tasks/:id` | DELETE | Удалить серию |
| `/tasks/:id/tags` | POST | Добавить тег задаче (`tag_id` или `name`) |
| `/tasks/:id/tags/:tag_id` | DELETE | Снять тег |
| `/tags` | GET / POST | Список / создание тега |
| `/tags/:id` | PATCH / DELETE | Редактирование / удаление тега (системные защищены 403) |
| `/tasks/:id/occurrences/:date` | GET | Состояние конкретного дня периодической задачи |
| `/tasks/:id/occurrences/:date` | PATCH | Переопределить день (статус / время / название) |
| `/tasks/:id/occurrences/:date` | DELETE | Отменить только этот день |

`GET /tasks` возвращает обёртку, а не голый массив:

```json
{
  "from": "2026-06-25",
  "to":   "2026-06-30",
  "items": [ { ...TaskItem... }, ... ]
}
```

`from`/`to` отражают фактическое окно (с применёнными дефолтами: сегодня и +30 дней).

### Примеры

Создать ежедневную задачу:

```bash
curl -X POST http://localhost:3000/api/v1/tasks \
  -H "Content-Type: application/json" \
  -d '{
    "task": {
      "name": "Ежедневный обзвон",
      "scheduled_at": "2026-06-23T10:00:00Z",
      "recurrence_rule_attributes": {
        "frequency": "daily",
        "interval": 1,
        "starts_on": "2026-06-23"
      }
    }
  }'
```

Получить расписание на неделю:

```bash
curl "http://localhost:3000/api/v1/tasks?from=2026-06-23&to=2026-06-29"
```

Отметить выполненным конкретный день периодической задачи (другие дни не затрагиваются):

```bash
curl -X PATCH http://localhost:3000/api/v1/tasks/1/occurrences/2026-06-25 \
  -H "Content-Type: application/json" \
  -d '{ "occurrence": { "status": "completed" } }'
```

Отменить только один день серии:

```bash
curl -X DELETE http://localhost:3000/api/v1/tasks/1/occurrences/2026-06-26
```

#### Под Windows / PowerShell

PowerShell 5.1 при передаче в native-команды снимает двойные кавычки из single-quoted строк — `curl.exe` получает невалидный JSON и Rails отвечает `400 Bad Request`. Два рабочих варианта:

```powershell
# Вариант А: stop-parsing token --% + экранирование двойных кавычек
curl.exe --% -X POST http://localhost:3000/api/v1/tasks -H "Content-Type: application/json" -d "{\"task\":{\"name\":\"Daily round\",\"scheduled_at\":\"2026-06-25T10:00:00Z\",\"recurrence_rule_attributes\":{\"frequency\":\"daily\",\"interval\":1,\"starts_on\":\"2026-06-25\"}}}"

# Вариант Б: тело в файле (надёжнее, поддерживает кириллицу UTF-8)
@'
{"task":{"name":"Обход 5-го корпуса","scheduled_at":"2026-06-25T10:00:00Z","recurrence_rule_attributes":{"frequency":"daily","interval":1,"starts_on":"2026-06-25"}}}
'@ | Set-Content -Encoding utf8 body.json
curl.exe -X POST http://localhost:3000/api/v1/tasks -H "Content-Type: application/json" --data-binary "@body.json"
```

Для GET-запросов без тела никаких трюков не нужно — `curl.exe "http://localhost:3000/api/v1/tasks?from=2026-06-25&to=2026-06-30"` работает как есть. Альтернативно — Swagger UI на `/api-docs` или Web UI на `/`, оба без квотинг-боли.

## Архитектурные решения

### Хранение периодических задач (проблема бесконечности)

Серия задач хранится **одной** записью `Task` + связанным `RecurrenceRule`. Конкретные появления не материализуются заранее — они вычисляются на лету сервисом [`TasksQuery`](app/services/tasks_query.rb) при запросе списка в окно дат.

Это значит:

- задача «ежедневный обход» без даты окончания занимает **2 строки в БД** (Task + RecurrenceRule), а не миллион;
- API всегда требует пару `from`/`to` для разворачивания, и окно ограничено `MAX_WINDOW_DAYS = 366` (валидируется в сервисе).

### Состояние конкретного экземпляра (lazy materialization)

`TaskOccurrence` — это «overlay» поверх серии для одного дня. Он создаётся **только когда что-то меняется** для конкретного дня:

- врач отметил один день выполненным → создаётся `TaskOccurrence(status: completed)`;
- перенесли время одного появления → `TaskOccurrence(scheduled_at: ...)`;
- отменили один день → `TaskOccurrence(cancelled: true)`.

Если для дня нет override-записи, он считается виртуальным со статусом `pending` и временем из шаблона серии. Так у каждого появления естественно своё независимое состояние, при этом таблица остаётся компактной.

### Исключения из правил (бонус)

Реализованы через ту же `TaskOccurrence`:

- `PATCH /tasks/:id/occurrences/:date` с `scheduled_at` или `name`/`description` — «отрывает» день от серии (status/время/название перекрываются);
- `DELETE /tasks/:id/occurrences/:date` — отменяет один день, серия продолжается.

При выдаче списка серия и overrides склеиваются: для каждой расчётной даты сначала ищется override-запись, и если её нет — используются значения шаблона.

### Системные теги

Три тега — `отчетность`, `операции`, `звонок` — создаются seed-скриптом со флагом `system: true`. На уровне модели:

- `before_destroy` блокирует удаление (`throw :abort`);
- валидация `system_tag_immutable` запрещает менять `name` и `system`;
- контроллер `TagsController` возвращает на эти случаи `403 Forbidden`.

### Структура задачи в списке

В одном ответе на `GET /tasks` смешиваются одноразовые задачи и появления периодических. Чтобы клиент мог их различать единообразно, оба формата сериализуются в один `TaskItem`:

```json
{
  "task_id": 1,
  "occurrence_id": null,
  "occurrence_date": "2026-06-23",
  "name": "Ежедневный обзвон",
  "description": "Список пациентов в вложении к серии",
  "scheduled_at": "2026-06-23T10:00:00Z",
  "status": "pending",
  "recurring": true,
  "override": false,
  "tags": [{ "id": 3, "name": "звонок", "system": true }]
}
```

Одноразовая задача имеет `occurrence_date: null` и `recurring: false`. Материализованный override несёт `override: true` и заполненный `occurrence_id`. Конкретный экземпляр серии адресуется парой `(task_id, occurrence_date)`.

## Тесты

```bash
docker compose exec web bundle exec rspec
# или локально:
bundle exec rspec
```

Покрытие: модели (Task, Tag, RecurrenceRule, TaskOccurrence), сервис `TasksQuery`, request-specs на все эндпоинты, бизнес-сценарии (системные теги, разворачивание повторов, изоляция статуса одного дня).

## Сделанные допущения

- **Аутентификация не реализована.** ТЗ не требует, и работа сосредоточена на бизнес-логике трекера. Добавляется отдельной задачей (Devise/JWT, токен из заголовка и т.п.).
- **Часовой пояс — UTC.** `scheduled_at` принимается и возвращается в UTC; локализацию оставляю клиенту.
- **`status` серии = статус для одноразовой задачи.** У периодической задачи поле `status` существует, но эффективный статус берётся с уровня occurrence — это позволило не вводить отдельную модель «шаблон серии vs одноразовая задача» и сохранить простую схему.
- **Время дня периодической задачи** берётся из `scheduled_at` шаблона серии (часы:минуты). При создании override можно перекрыть полным `scheduled_at`.
- **Максимальное окно выдачи — 366 дней.** Защита от случайно широких запросов. Константа `TasksQuery::MAX_WINDOW_DAYS`.
- **Удаление серии каскадно удаляет правило повтора и все материализованные оккуренсы.**
- **Тип `task_status` — Postgres enum.** Используется и для `tasks.status`, и для `task_occurrences.status`.

## Структура проекта

```
app/
├── controllers/api/v1/   # TasksController, TagsController, TaskTagsController, TaskOccurrencesController
├── models/               # Task, Tag, TaskTag, RecurrenceRule, TaskOccurrence
├── serializers/          # Простые POJOs: Task/Tag/TaskItem/TaskOccurrence/RecurrenceRule
└── services/             # TasksQuery (разворачивание окна) + TaskItem (DTO)
config/                   # routes.rb, database.yml, environments/, initializers/
db/migrate/               # 5 миграций
public/index.html         # Демо-SPA для ручной проверки API (vanilla JS)
spec/                     # rspec, factories, models, services, requests/api/v1
swagger/v1/swagger.yaml   # OpenAPI 3.0.3, отдаётся через /api-docs
Dockerfile + docker-compose.yml
HISTORY.md                # экспорт чата с LLM
```

## Дальнейшие улучшения (out of scope ТЗ)

- Аутентификация и роли (врач / администратор)
- Pagination в `/tasks` (сейчас весь массив — окно ограничено сверху, но при плотных правилах + большом окне это всё ещё сотни элементов)
- Фоновая задача-«генератор» для уведомлений по приближающимся оккуренсам
- Локализация / явный TZ на уровень пользователя
- N+1 защита для тегов в `TasksQuery` уже сделана через `includes`, но при необходимости можно добавить `bullet`
