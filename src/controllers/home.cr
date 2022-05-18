class Home < Application
  base "/"

  def index
    redirect_to "/index.html"
  end
end
