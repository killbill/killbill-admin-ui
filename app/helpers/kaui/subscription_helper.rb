module Kaui
  module SubscriptionHelper

    def humanized_subscription_product_category(sub)
      if !sub.present? or !sub.product_category.present?
        nil
      else
        humanized_product_category(sub.product_category)
      end
    end

    def humanized_product_category(product_category)
      if product_category == 'BASE'
        'Base'
      elsif product_category == 'ADD_ON'
        'Add-on'
      else
        product_category.downcase.capitalize
      end
    end

    def humanized_subscription_product_name(sub)
      if !sub.present? or !sub.product_name.present?
        nil
      else
        humanized_product_name(sub.product_name)
      end
    end

    def humanized_product_name(product_name)
        product_name.downcase.capitalize
    end

    def humanized_subscription_billing_period(sub)
      if !sub.present? or !sub.billing_period.present?
        nil
      else
        humanized_billing_period(sub.billing_period)
      end
    end

    def humanized_billing_period(billing_period)
      if billing_period == 'NO_BILLING_PERIOD'
        'No billing period'
      else
        billing_period.downcase.capitalize
      end
    end

    def humanized_subscription_price_list(sub, show_default=true)
      if !sub.present? or !sub.price_list.present? or (!show_default and sub.price_list.upcase == 'DEFAULT')
        nil
      else
        sub.price_list.downcase.capitalize
      end
    end

    def humanized_subscription_full_product_name(sub)
      humanized_product_name   = humanized_subscription_product_name(sub)
      humanized_billing_period = humanized_subscription_billing_period(sub)
      humanized_price_list     = humanized_subscription_price_list(sub, false)

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

    def humanized_subscription_phase_type(sub)
      sub.phase_type
    end

    def humanized_subscription_start_date(sub, account)
      if !sub.present? or !sub.start_date.present? or !account.present? or !account.time_zone.present?
        nil
      else
        format_date(sub.start_date, account.time_zone).html_safe
      end
    end

    def humanized_subscription_charged_through_date(sub, account)
      if !sub.present? or !sub.charged_through_date.present? or !account.present? or !account.time_zone.present?
        nil
      else
        format_date(sub.charged_through_date, account.time_zone).html_safe
      end
    end

    def humanized_subscription_cancelled_date(sub, account)
      if !sub.present? or !sub.cancelled_date.present? or !account.present? or !account.time_zone.present?
        nil
      else
        "Entitlement date: #{format_date(sub.cancelled_date, account.time_zone)}"
      end
    end

    def humanized_subscription_billing_start_date(sub, account)
      if !sub.present? or !sub.billing_start_date.present? or !account.present? or !account.time_zone.present?
        nil
      else
        format_date(sub.billing_start_date, account.time_zone).html_safe
      end
    end

    def humanized_subscription_billing_end_date(sub, account)
      if !sub.present? or !sub.billing_end_date.present? or !account.present? or !account.time_zone.present?
        nil
      else
        "Billing date: #{format_date(sub.billing_end_date, account.time_zone)}"
      end
    end

    def humanized_subscription_cancelled_information(sub, account)
      if !sub.present? or !sub.cancelled_date.present? or !account.present? or !account.time_zone.present?
        nil
      else
        "#{humanized_subscription_cancelled_date(sub, account)}<br/>#{humanized_subscription_billing_end_date(sub, account)}".html_safe
      end
    end

    def humanized_time_unit(time_unit)
      time_unit.downcase.capitalize
    end


    def is_subscription_future_cancelled?(sub, account)
      sub.present? && sub.state != 'CANCELLED' && sub.billing_end_date.present? && Time.parse(sub.billing_end_date) > current_time(account.time_zone)
    end

    def is_subscription_cancelled?(sub)
      sub.present? and sub.billing_end_date.present?
    end
  end
end
