class Task < ApplicationRecord
  STATUSES = %w[pending in_progress completed cancelled].freeze

  belongs_to :recurrence_rule, optional: true, dependent: :destroy
  has_many :task_tags, dependent: :destroy
  has_many :tags, through: :task_tags
  has_many :task_occurrences, dependent: :destroy

  accepts_nested_attributes_for :recurrence_rule, allow_destroy: true

  enum :status, STATUSES.index_with(&:itself), validate: true

  validates :name, presence: true, length: { maximum: 255 }
  validates :scheduled_at, presence: true

  scope :recurring, -> { where.not(recurrence_rule_id: nil) }
  scope :one_off,   -> { where(recurrence_rule_id: nil) }

  def recurring?
    recurrence_rule_id.present?
  end

  # Returns or builds (without saving) the occurrence record for a given date.
  # The record carries the effective status / overrides for that day.
  def occurrence_for(date)
    task_occurrences.find_or_initialize_by(occurrence_date: date)
  end
end
