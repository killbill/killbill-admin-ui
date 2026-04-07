# frozen_string_literal: true

module Kaui
  module SubscriptionHelper
    def humanized_subscription_product_category(sub)
      if sub.blank? || sub.product_category.blank?
        nil
      else
        humanized_product_category(sub.product_category)
      end
    end

    def humanized_product_category(product_category)
      if product_category.to_s == 'BASE'
        'Base'
      elsif product_category.to_s == 'ADD_ON'
        'Add-on'
      else
        product_category.to_s.downcase.capitalize
      end
    end

    def humanized_subscription_product_name(sub, catalog = nil)
      if sub.blank? || sub.product_name.blank?
        nil
      else
        product = catalog&.products&.find { |p| p.name == sub.product_name }
        humanized_product_name(!product.nil? && product.pretty_name.present? ? product.pretty_name : sub.product_name)
      end
    end

    def humanized_subscription_pretty_plan_name(sub, catalog = nil)
      if sub.blank? || sub.product_name.blank?
        nil
      else
        product = catalog&.products&.find { |p| p.name == sub.product_name }
        return nil if product.nil?

        plan = product.plans.find { |p| p.name == sub.plan_name }
        plan.nil? || plan.pretty_name.blank? ? nil : plan.pretty_name
      end
    end

    def humanized_product_name(product_name)
      # Don't change the casing to avoid confusions (could lead to different products with different casing)
      product_name
    end

    def humanized_subscription_billing_period(sub)
      if sub.blank? || sub.billing_period.blank?
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

    def humanized_subscription_price_list(sub, show_default)
      if sub.blank? || sub.price_list.blank? || (!show_default && (sub.price_list.upcase == 'DEFAULT'))
        nil
      else
        sub.price_list.downcase.capitalize
      end
    end

    def humanized_subscription_plan_or_product_name(sub, catalog = nil)
      pretty_plan_name = humanized_subscription_pretty_plan_name(sub, catalog)
      return pretty_plan_name unless pretty_plan_name.nil?

      humanized_product_name   = humanized_subscription_product_name(sub, catalog)
      humanized_billing_period = humanized_subscription_billing_period(sub)
      humanized_price_list     = humanized_subscription_price_list(sub, false)

      if humanized_billing_period.nil?
        if humanized_price_list.nil?
          humanized_product_name + humanized_price_override(sub, '', '(', ')')
        else
          "#{humanized_product_name} (#{humanized_price_list.downcase}#{humanized_price_override(sub)})"
        end
      elsif humanized_price_list.nil?
        "#{humanized_product_name} (#{humanized_billing_period.downcase}#{humanized_price_override(sub)})"
      else
        "#{humanized_product_name} (#{humanized_billing_period.downcase}, #{humanized_price_list.downcase}#{humanized_price_override(sub)})"
      end
    end

    def humanized_price_override(sub, separation = ', ', open_bracket = '', close_bracket = '')
      if sub.plan_name.scan(/ *-\d+$/).empty?
        ''
      else
        current_plan = sub.prices.select { |price| price['phaseType'] == sub.phase_type && price['planName'] == sub.plan_name }
        price_override = current_plan.last ? (current_plan.last['fixedPrice'] || current_plan.last['recurringPrice']) : nil

        if price_override.blank?
          ''
        else
          span = "<span data-toggle=\"popover\" class=\"price-override-popover\" data-content=\"#{price_override}\"><b>price override</b></span>"
          "#{open_bracket}#{separation}#{span}#{close_bracket}"
        end
      end
    end

    def catalog_for_subscription(sub, catalogs)
      return nil if catalogs.blank? || sub&.start_date.blank?

      start_date = begin
        Date.parse(sub.start_date)
      rescue StandardError
        nil
      end
      return catalogs.last if start_date.nil?

      # Find the latest catalog version whose effective_date <= subscription start_date
      best = catalogs.select do |c|
        begin
          Date.parse(c.effective_date) <= start_date
        rescue StandardError
          false
        end
      end.max_by(&:effective_date)

      # Fall back to the oldest version if none precedes the start_date
      best || catalogs.first
    end

    def humanized_subscription_phase_type(sub)
      sub.phase_type
    end

    def humanized_subscription_start_date(sub, account)
      if sub.blank? || sub.start_date.blank? || account.blank? || account.time_zone.blank?
        nil
      else
        format_date(sub.start_date, account.time_zone)
      end
    end

    def humanized_subscription_charged_through_date(sub, account)
      if sub.blank? || sub.charged_through_date.blank? || account.blank? || account.time_zone.blank?
        nil
      else
        format_date(sub.charged_through_date, account.time_zone)
      end
    end

    def humanized_subscription_cancelled_date(sub, account)
      if sub.blank? || sub.cancelled_date.blank? || account.blank? || account.time_zone.blank?
        nil
      else
        "Entitlement date: #{format_date(sub.cancelled_date, account.time_zone)}"
      end
    end

    def humanized_subscription_billing_start_date(sub, account)
      if sub.blank? || sub.billing_start_date.blank? || account.blank? || account.time_zone.blank?
        nil
      else
        format_date(sub.billing_start_date, account.time_zone)
      end
    end

    def humanized_subscription_billing_end_date(sub, account)
      if sub.blank? || sub.billing_end_date.blank? || account.blank? || account.time_zone.blank?
        nil
      else
        "Billing date: #{format_date(sub.billing_end_date, account.time_zone)}"
      end
    end

    def humanized_subscription_cancelled_information(sub, account)
      if sub.blank? || sub.cancelled_date.blank? || account.blank? || account.time_zone.blank?
        nil
      else
        safe_join([humanized_subscription_cancelled_date(sub, account), humanized_subscription_billing_end_date(sub, account)], tag.br)
      end
    end

    def humanized_time_unit(time_unit)
      time_unit.downcase.capitalize
    end

    def subscription_future_cancelled?(sub, account)
      sub.present? && sub.state != 'CANCELLED' && sub.billing_end_date.present? && Time.zone.parse(sub.billing_end_date) > current_time(account.time_zone)
    end

    def subscription_cancelled?(sub)
      sub.present? and sub.billing_end_date.present?
    end

    def paging_button_class(num, current_page)
      num == current_page ? 'btn btn-primary' : 'btn btn-custom'
    end
  end
end
