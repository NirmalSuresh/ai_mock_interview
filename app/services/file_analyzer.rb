class FileAnalyzer
  def self.call(blob)
    path = download_to_tmp(blob)

    case blob.content_type
    when "application/pdf"
      { pdf: path }
    when /^image\//
      { image: path }
    when /^audio\//
      { audio: path }
    else
      { file: path }
    end
  end

  def self.download_to_tmp(blob)
    tmp = Tempfile.new(["upload", File.extname(blob.filename.to_s)])
    tmp.binmode
    tmp.write(blob.download)
    tmp.rewind
    tmp.path
  end
end
