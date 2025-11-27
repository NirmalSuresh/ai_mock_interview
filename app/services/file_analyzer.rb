class FileAnalyzer
  def self.call(blob)
    tmp_path = download_to_tmp(blob)

    base64_data = Base64.strict_encode64(File.read(tmp_path))
    mime = blob.content_type

    data_url = "data:#{mime};base64,#{base64_data}"

    case mime
    when "application/pdf"
      { pdf: data_url }
    when /^image\//
      { image: data_url }
    when /^audio\//
      { audio: data_url }
    else
      { file: data_url }
    end
  end

  def self.download_to_tmp(blob)
    ext = File.extname(blob.filename.to_s)
    file = Tempfile.new(["upload", ext])
    file.binmode
    file.write(blob.download)
    file.rewind
    file.path
  end
end
