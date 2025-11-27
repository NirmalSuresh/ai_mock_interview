class Message < ApplicationRecord
  belongs_to :assistant_session

  has_one_attached :attachment

  validates :role, presence: true
  validates :content, presence: true, unless: -> { attachment.attached? }

  validate :attachment_type_and_size

  MAX_ATTACHMENT_BYTES = 5.megabytes

  ALLOWED_TYPES = [
    "image/png", "image/jpeg", "image/jpg", "image/gif",
    "audio/mpeg", "audio/mp3", "audio/wav", "audio/webm",
    "application/pdf",
    "text/plain",
    "application/msword",
    "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
  ]

  # ---------------------------
  # VALIDATIONS
  # ---------------------------
  def attachment_type_and_size
    return unless attachment.attached?

    unless ALLOWED_TYPES.include?(attachment.blob.content_type)
      errors.add(:attachment, "unsupported file format")
    end

    if attachment.blob.byte_size > MAX_ATTACHMENT_BYTES
      errors.add(:attachment, "is too large (max 5 MB)")
    end
  end

  # ---------------------------
  # HELPERS
  # ---------------------------
  # Cloudinary URL (SAFE & WORKS ON RENDER)
  def attachment_url
    attachment.url if attachment.attached?
  end

  def attachment_content_type
    attachment&.blob&.content_type
  end

  def file?
    attachment.attached?
  end

  def image?
    attachment_content_type&.start_with?("image/")
  end

  def audio?
    attachment_content_type&.start_with?("audio/")
  end

  def pdf?
    attachment_content_type == "application/pdf"
  end

  def document?
    %w[
      text/plain
      application/msword
      application/vnd.openxmlformats-officedocument.wordprocessingml.document
    ].include?(attachment_content_type)
  end
end
