class SettingsController < JanitorController
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  skip_before_action :verify_authenticity_token

  def notifications
    if request.get?
      @email_settings = EmailSettings.new
      return render template: 'settings/notifications'
    end

    @email_settings = EmailSettings.new
    @email_settings.smtp_host   = params[:smtp_host]
    @email_settings.smtp_port   = params[:smtp_port]
    @email_settings.smtp_domain = params[:smtp_domain]
    @email_settings.smtp_admin_email  = params[:smtp_admin_email]
    @email_settings.smtp_no_reply = params[:smtp_no_reply]

    if params["test_settings"] == "true"
      begin
        m = AccountMailer.test_email(to: @email_settings.smtp_admin_email, settings: @email_settings)
        m.deliver_now
      rescue => e
        Rails.logger.error("Failed to send email using next settings: #{params.to_json}, Error: #{e}")
      end
      return
    else
      @email_settings.save
    end


  end
end
