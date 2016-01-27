class AccountMailer < ApplicationMailer
  after_action :set_delivery_options

  def set_delivery_options
    mail.delivery_method.settings[:address] = @smtp_settings.smtp_host
    mail.delivery_method.settings[:port]    = @smtp_settings.smtp_port
    mail.delivery_method.settings[:domain]  = @smtp_settings.smtp_domain
    mail.delivery_method.settings[:address] = @smtp_settings.smtp_host
    mail.delivery_method.settings[:enable_starttls_auto] = false
  end

  def mail_headers(settings)
    settings ||= EmailSettings.new
    { reply_to: settings.smtp_no_reply, from: settings.smtp_no_reply, return_path: settings.smtp_no_reply}
  end

  def test_email(args)
    @smtp_settings = args[:settings] || EmailSettings.new
    mail_headers = mail_headers(args[:settings])
    mail_headers[:to] = args[:to]
    mail_headers[:subject] = 'AWS dashboard test settings email'
    mail(mail_headers)
  end
end
