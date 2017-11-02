require 'sanitize'

module Processable
  extend ActiveSupport::Concern
  
  def process(params, non_user_params=nil)
    if params.respond_to?(:to_unsafe_h)
      params = params.to_unsafe_h
    end
    params = (params || {}).with_indifferent_access
    non_user_params = (non_user_params || {}).with_indifferent_access
    @processing_errors = []
    res = self.process_params(params.with_indifferent_access, non_user_params)
    if res == false
      @errored = true
      return false
    else
      self.save
    end
  end
  
  def processing_errors
    @processing_errors || []
  end
  
  def add_processing_error(str)
    @processing_errors ||= []
    @processing_errors << str
  end
  
  def errored?
    @errored || processing_errors.length > 0
  end
  
  def process_license(license)
    self.settings['license'] = OBF::Utils.parse_license(license);
  end
  
  def process_string(str)
    Sanitize.fragment(str).strip
  end
  
  def process_html(html)
    Sanitize.fragment(html, Sanitize::Config::RELAXED)
  end
  
  def process_color(str)
    str = str.strip
    if str.match(/^(#[0-9a-f]{3}|#(?:[0-9a-f]{2}){2,4}|(rgb|hsl)a?\((\d+%?(deg|rad|grad|turn)?[,\s]+){2,3}[\s\/]*[\d\.]+%?\))$/)
      return str
    else
      return nil
    end
  end
  
  def process_boolean(bool)
    return bool == true || bool == '1' || bool == 'true'
  end

  
  module ClassMethods
    def process_new(params, non_user_params=nil)
      obj = self.new
      obj.process(params, non_user_params)
      obj
    end
  end
end