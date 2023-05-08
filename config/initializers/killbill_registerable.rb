# frozen_string_literal: true

Devise.add_module(:killbill_registerable,
                  route: :registration,
                  controller: :registrations,
                  model: 'kaui/killbill_registerable')
