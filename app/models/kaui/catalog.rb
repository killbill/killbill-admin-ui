class Kaui::Catalog < KillBillClient::Model::Catalog

  class << self

    def get_catalog_json(latest, options)

      catalogs = KillBillClient::Model::Catalog.get_tenant_catalog('json', nil, options)
      return catalogs.length > 0 ? catalogs[catalogs.length - 1] : nil if latest

      # Order by latest
      result = []
      catalogs.sort! { |l, r| r.effective_date <=> l.effective_date }

      catalogs.each_with_index do |current_catalog, idx|
        result << {:version => idx,
                   :version_date => current_catalog.effective_date,
                   :currencies => current_catalog.currencies,
                   :plans => build_existing_simple_plans(current_catalog)}
      end
      result
    end

    def build_ao_mapping(catalog)
      tmp = {}
      catalog.products.each do |p|
        p.available.each do |ap|
          if !tmp.has_key?(ap)
            tmp[ap] = []
          end
          tmp[ap] << p.name
        end
      end unless catalog.nil?
      tmp.map { |e,v| "#{e}:#{v.join(",")}" }.join(";")
    end


    def get_catalog_xml(options)

      catalog_xml = KillBillClient::Model::Catalog.get_tenant_catalog('xml', nil, options)

      parsed_catalog = parse_catalog_xml(catalog_xml)

      result = []
      parsed_catalog.keys.each_with_index do |version_date, i|
        entry = {}
        entry[:version] = i
        entry[:version_date] = version_date
        entry[:xml] = parsed_catalog[version_date]
        result << entry
      end
      result
    end

    private

    def build_existing_simple_plans(catalog)

      tmp = catalog.products.map do |p|
        p.plans.each do |plan|
          class << plan
            attr_accessor :product_name
            attr_accessor :product_category
          end
          plan.product_name = p.name
          plan.product_category = p.type
        end
      end.flatten!

      selected = tmp.select { |p| p.phases.length.to_i <= 2 && p.phases[p.phases.length - 1].type == "EVERGREEN" }

      currencies = catalog.currencies

      result = []
      selected.each do |plan|
        has_trial = plan.phases[0].type == 'TRIAL'

        simple_plan = KillBillClient::Model::SimplePlanAttributes.new

        # Embellish SimplePlanAttributes to contain a map currency -> amount (required in the view)
        class << simple_plan
          attr_accessor :prices
        end
        simple_plan.prices = plan.phases[-1].prices.inject({}) { |r, e| r[e.currency] = e.value; r }

        simple_plan.plan_id = plan.name
        simple_plan.product_name = plan.product_name
        simple_plan.product_category = plan.product_category
        simple_plan.currency = currencies[0]
        simple_plan.amount = simple_plan.prices[currencies[0]]
        simple_plan.billing_period = plan.billing_period
        simple_plan.trial_length = has_trial ? plan.phases[0].duration.number : 0
        simple_plan.trial_time_unit = has_trial ? plan.phases[0].duration.unit : "N/A"

        result << simple_plan
      end
      result
    end

    def parse_catalog_xml(input_xml)

      require 'nokogiri'

      doc = Nokogiri::XML(input_xml)
      doc_versions = doc.xpath("//version")

      doc_versions.inject({}) do |hsh, v|

        # Replace node 'version' with 'catalog' and add the attributes
        v.name = 'catalog'
        v['xmlns:xsi'] = "http://www.w3.org/2001/XMLSchema-instance"
        v['xsi:noNamespaceSchemaLocation'] = "CatalogSchema.xsd"
        # Extract version
        version = v.search("effectiveDate").text

        # Add entry
        hsh[version] = '<?xml version="1.0" encoding="utf-8"?>' + format_xml(v.to_s)
        hsh
      end
    end


    def format_xml(unformatted_xml)

      require "rexml/document"

      # Start by removing all spaces before using rexml
      unformatted_xml.gsub!(/>\s+</, "><")

      result = ""
      pdoc = REXML::Document.new(unformatted_xml)
      formatter = REXML::Formatters::Pretty.new(4)
      formatter.compact = true
      formatter.write(pdoc, result)
      result
    end
  end



end
