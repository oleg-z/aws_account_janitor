class AccountMailer < ApplicationMailer
  def use_settings(settings)
    @settings = settings
    apply_smtp_settings
  end

  def apply_smtp_settings(settings)
    settings ||= EmailSettings.new
    delivery_method = :smtp
    smtp_settings = {
      :address => settings.smtp_host,
      :port    => settings.smtp_port,
      :domain  => settings.smtp_domain,
      :user_name=>nil,
      :password=>nil,
      :authentication=>nil,
      :enable_starttls_auto=>false
    }
    { reply_to: settings.smtp_no_reply, from: settings.smtp_no_reply, return_path: settings.smtp_no_reply}
  end

  def test_email(args)
    mail_headers = apply_smtp_settings(args[:settings])
    mail_headers[:to] = args[:to]
    mail_headers[:subject] = 'AWS dashboard test settings email'
    mail(mail_headers)
  end
end
