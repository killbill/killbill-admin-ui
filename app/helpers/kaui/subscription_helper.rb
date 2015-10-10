module Kaui
  module SubscriptionHelper

    def humanized_product_category(sub)
      if !sub.present? or !sub.product_category.present?
        nil
      elsif sub.product_category == 'BASE'
        'Base'
      elsif sub.product_category == 'ADD_ON'
        'Add-on'
      else
        sub.product_category.downcase.capitalize
      end
    end

    def humanized_product_name(sub)
      if !sub.present? or !sub.product_name.present?
        nil
      else
        sub.product_name.downcase.capitalize
      end
    end

    def humanized_billing_period(sub)
      if !sub.present? or !sub.billing_period.present?
        nil
      elsif sub.billing_period == 'NO_BILLING_PERIOD'
        'No billing period'
      else
        sub.billing_period.downcase.capitalize
      end
    end

    def humanized_price_list(sub, show_default=true)
      if !sub.present? or !sub.price_list.present? or (!show_default and sub.price_list.upcase == 'DEFAULT')
        nil
      else
        sub.price_list.downcase.capitalize
      end
    end

    def humanized_full_product_name(sub)
      humanized_product_name   = humanized_product_name(sub)
      humanized_billing_period = humanized_billing_period(sub)
      humanized_price_list     = humanized_price_list(sub, false)

      if humanized_billing_period.nil?
        if humanized_price_list.nil?
          humanized_product_name
        else
          humanized_product_name+ ' (' + humanized_price_list.downcase + ')'
        end
      else
        if humanized_price_list.nil?
          humanized_product_name + ' (' + humanized_billing_period.downcase + ')'
        else
          humanized_product_name+ ' (' + humanized_billing_period.downcase + ', ' + humanized_price_list.downcase + ')'
        end
      end
    end

    def humanized_start_date(sub, account)
      if !sub.present? or !sub.start_date.present? or !account.present? or !account.time_zone.present?
        nil
      else
        format_date(sub.start_date, account.time_zone).html_safe
      end
    end

    def humanized_charged_through_date(sub, account)
      if !sub.present? or !sub.charged_through_date.present? or !account.present? or !account.time_zone.present?
        nil
      else
        format_date(sub.charged_through_date, account.time_zone).html_safe
      end
    end

    def humanized_cancelled_date(sub, account)
      if !sub.present? or !sub.cancelled_date.present? or !account.present? or !account.time_zone.present?
        nil
      else
        cancelled_date = format_date(sub.cancelled_date, account.time_zone).html_safe
        if Time.parse(sub.cancelled_date) > Time.now
          'Pending cancellation on ' + cancelled_date
        else
          'Canceled on ' + cancelled_date
        end
      end
    end

    def humanized_billing_start_date(sub, account)
      if !sub.present? or !sub.billing_start_date.present? or !account.present? or !account.time_zone.present?
        nil
      else
        format_date(sub.billing_start_date, account.time_zone).html_safe
      end
    end

    def humanized_billing_end_date(sub, account)
      if !sub.present? or !sub.billing_end_date.present? or !account.present? or !account.time_zone.present?
        nil
      else
        format_date(sub.billing_end_date, account.time_zone).html_safe
      end
    end

    def is_future_cancelled?(sub)
      sub.present? and sub.billing_end_date.present? and Time.parse(sub.billing_end_date) > Time.now
    end

    def is_cancelled?(sub)
      sub.present? and sub.billing_end_date.present?
    end
  end
end
