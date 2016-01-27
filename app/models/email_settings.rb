class EmailSettings < ActiveRecord::Base
  self.table_name = "settings"
  attr_accessor :smtp_host
  attr_accessor :smtp_port
  attr_accessor :smtp_domain
  attr_accessor :smtp_no_reply
  attr_accessor :smtp_admin_email

  def initialize(*args)
    super(*args)
    @smtp_host     = get_field_value(:smtp_host)
    @smtp_port     = get_field_value(:smtp_port)
    @smtp_domain   = get_field_value(:smtp_domain)
    @smtp_no_reply = get_field_value(:smtp_no_reply)
    @smtp_admin_email = get_field_value(:smtp_admin_email)
  end

  def save
    set_field_value(:smtp_host)
    set_field_value(:smtp_port)
    set_field_value(:smtp_domain)
    set_field_value(:smtp_no_reply)
    set_field_value(:smtp_admin_email)
  end

  private

  def get_field_value(field_name)
    r = SettingRecord.find_by(field_name: field_name)
    r ? r.field_value : nil
  end

  def set_field_value(field_name)
    r = SettingRecord.find_by(field_name: field_name)
    r ||= SettingRecord.new(field_name: field_name)
    r.field_value = send(field_name)
    r.save
  end
end
