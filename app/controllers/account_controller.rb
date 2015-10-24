class AccountController < JanitorController
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  def index
    @accounts = AwsAccount.all()
  end

  def new

  end

  def create
    a = AwsAccount.new
    fail "Alias couldn't be empty" if params[:alias].to_s.empty?
    a.alias = params[:alias].strip
    a.access_key = params[:access_key]
    a.secret_key = params[:secret_key]
    a.role = params[:role]
    a.identifier = params[:identifier]
    a.email = params[:email]
    a.save
    #render text: "Account has been created!"
    redirect_to action: :index
  end

  def update
    a = AwsAccount.find(params[:id])
    a.alias      = params[:alias].to_s.strip
    a.access_key = params[:access_key].to_s.strip
    a.secret_key = params[:secret_key].to_s.strip  unless params[:secret_key].to_s.strip.empty?
    a.role       = params[:role].to_s.strip
    a.save
    redirect_to action: :index
  end

  def destroy
    AwsAccount.find(params[:id]).delete
    redirect_to action: :index
  end

  def show
    @account = AwsAccount.find(params[:id])
  end
end
