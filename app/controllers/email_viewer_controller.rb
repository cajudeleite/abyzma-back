class EmailViewerController < ApplicationController
  def index
    @email_dirs = Dir.glob(Rails.root.join("tmp/letter_opener/*")).select { |d| File.directory?(d) }
    @email_dirs.sort_by! { |d| File.mtime(d) }.reverse!
  end
  
  def show
    email_dir = Rails.root.join("tmp/letter_opener/#{params[:id]}")
    @html_file = email_dir.join("rich.html")
    @text_file = email_dir.join("plain.html")
    
    if File.exist?(@html_file)
      @email_content = File.read(@html_file)
    elsif File.exist?(@text_file)
      @email_content = File.read(@text_file)
    else
      redirect_to email_viewer_index_path, alert: "Email not found"
    end
  end
end
