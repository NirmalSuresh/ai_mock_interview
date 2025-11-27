class Message < ApplicationRecord
  belongs_to :assistant_session
  has_one_attached :file

  validate :acceptable_file

  private

  def acceptable_file
    return unless file.attached?

    # File size check
    if file.byte_size > 5.megabytes
      errors.add(:file, "is too large (max 5 MB)")
    end

    # Safe content-type check (NEVER use file.blob.content_type)
    unless file.content_type == "application/pdf"
      errors.add(:file, "must be a PDF")
    end
  end
end
