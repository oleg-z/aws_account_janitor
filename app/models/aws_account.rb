class AwsAccount < ActiveRecord::Base
  def authenticate(region)
    credentials = nil
    Rails.logger.info("Authenticating to #{self.alias}@#{region}")

    # switching region
    Aws.config.update(region: region)

    # updating credentials with current access and secrets
    credentials = Aws::Credentials.new(access_key, secret_key)
    Aws.config.update(credentials: credentials)

    # assuming role if defined
    unless role.strip.empty?
      tmp_credentials =
        Aws::STS::Client.new(access_key_id: access_key, secret_access_key: secret_key)
        .assume_role(role_arn: role, duration_seconds: 3600, role_session_name: "account-janitor")
        .credentials

      credentials = Aws::Credentials.new(
        tmp_credentials.access_key_id,
        tmp_credentials.secret_access_key,
        tmp_credentials.session_token
      )
      Aws.config.update(credentials: credentials)
    end
  end
end
