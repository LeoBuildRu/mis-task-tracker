class Tag < ApplicationRecord
  SYSTEM_TAG_NAMES = %w[отчетность операции звонок].freeze

  has_many :task_tags, dependent: :restrict_with_error
  has_many :tasks, through: :task_tags

  validates :name, presence: true, length: { maximum: 100 }
  validates :name, uniqueness: { case_sensitive: false }

  validate :system_tag_immutable, on: :update
  before_destroy :prevent_system_tag_destroy

  scope :system, -> { where(system: true) }
  scope :custom, -> { where(system: false) }

  def self.ensure_system_tags!
    SYSTEM_TAG_NAMES.each do |name|
      tag = where("LOWER(name) = ?", name.downcase).first
      if tag
        tag.update_columns(name: name, system: true) unless tag.system? && tag.name == name
      else
        create!(name: name, system: true)
      end
    end
  end

  private

  def system_tag_immutable
    return unless system?
    return if changes.empty?

    if name_changed? || system_changed?
      errors.add(:base, "Системный тег нельзя изменять")
    end
  end

  def prevent_system_tag_destroy
    return unless system?

    errors.add(:base, "Системный тег нельзя удалять")
    throw :abort
  end
end
