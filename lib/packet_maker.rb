require 'prawn'

module PacketMaker
  RENDER_VERSION=1
  def self.generate_download(word_paths, user_ids, opts)
    words = word_paths.map{|w| WordData.find_by_path(w) }.compact
    users = User.find_all_by_global_id(user_ids)
    
    Progress.update_current_progress(0.2, :generating_file)
    
    # generate hash based on settings and buttons
    keys = opts.keys.sort
    opts_string = keys.map{|k| "#{k.to_s}-#{opts[k].to_s}" }.join(':')
    buttons = words.map{|w| self.word_buttons(w, users).sort_by{|b| b['code'] || 'default' } }.flatten
    words_string = words.map{|w| "#{w.word}_#{w.locale}" }.sort.join('/')
    hash = Digest::MD5.hexdigest("packet::" + opts_string + "::" + buttons.to_json + "::" + words.map(&:created_at).join(','))
    remote_path = "packets/learn-aac/#{words_string}/#{hash}/v#{RENDER_VERSION}/packet.pdf"
    # check for existing download
    url = Uploader.check_existing_upload(remote_path)
    return url if url
    
    path = nil
    Progress.as_percent(0.2, 0.8) do
      path = generate_for(words, users, opts)
    end
    
    Progress.update_current_progress(0.9, :uploading_file)
    if File.exists?(path)
      url = Uploader.remote_upload(remote_path, path, 'application/pdf')
      File.unlink(path)
      url
    else
      nil
    end
  end
  
  RTL_SCRIPTS = %w(Arabic Hebrew Nko Kharoshthi Phoenician Syriac Thaana Tifinagh)
  
  def self.rtl_regex
    @res ||= /[#{RTL_SCRIPTS.map{ |script| "\\p{#{script}}" }.join}]/
  end

  # Confirmation dialog for printed packet should estimate number of pages
  # Check if there's already a pdf for the packaet
  # Generate a pdf for the packet
  # Upload the pdf to a shared space (with a human-readable filename, folder can be messy)
  
  def self.generate_for(words, users, opts)
    pdf = Prawn::Document.new(
      :page_layout => :portrait, 
      :page_size => [8.5*72, 11*72],
      :info => {
        :Title => 'Word Packet'
      }
    )
    @first_page = true
    font = opts['font'] if opts['font'] && File.exists?(opts['font'])
    font ||= File.expand_path('./TimesNewRoman.ttf', __FILE__)
    pdf.font(font) if File.exists?(font)
  
    words.each_with_index do |word, idx|
      Progress.as_percent(0.9 * idx.to_f / words.length, 0.9 * (idx + 1).to_f / words.length) do
        @word = word
        @page = 0
        # TODO: Options to exclude topic areas, or to only include entries with matching ids
        # (i.e. to print an individual book)
    
        # Header page should show all versions of the icons for matched users
        Progress.update_current_progress(0.05, :adding_header)
        add_header(word, users, pdf) if opts[:include_header] != false
        # Definition page: definition, bulleted usage examples, related core words
        Progress.update_current_progress(0.1, :adding_definitions)
        add_definitions(word, pdf) if opts[:include_definition] != false

        # Modeling page: tiles/cutouts with image phrase, explanation if any
        examples = (word.data['level_1_modeling_examples'] || []) + (word.data['level_2_modeling_examples'] || []) + (word.data['level_3_modeling_examples'] || [])
        Progress.update_current_progress(0.2, :adding_modeling_examples)
        add_cards('Modeling Examples', examples, pdf) if opts[:include_modeling] != false

        # Concise version:
        if opts[:concise]
          # Learning projects, activity ideas, topic-starters, send-homes, prompts: multiple per page, cards
          entries = []
          if opts[:include_learning_projects] != false
            entries += []
          end
          if opts[:include_activity_ideas] != false
            entries += []
          end
          if opts[:include_topic_starters] != false
            entries += []
          end
          if opts[:include_send_homes] != false
            entries += []
          end
          if opts[:include_prompts] != false
            entries += []
          end
          Progress.update_current_progress(0.5, :adding_cards)
          add_cards('Activities', entries, pdf)

          # Books: 4 spots per page (with page numbers)
          Progress.update_current_progress(0.8, :adding_books)
          add_books(word.data['books'], true, pdf) if opts[:include_books] != false
            # portrait, 4 per page, foldable (upside-down to match) with page numbers
            # include The End page with attributions
        # Verbose version:
        else
          # Learning projects: one per page
          Progress.update_current_progress(0.3, :adding_projects)
          add_activities('Learning Projects', word.data['learning_projects'], pdf) if opts[:include_learning_projects] != false
          # Activity ideas: one per page
          Progress.update_current_progress(0.4, :adding_ideas)
          add_activities('Activity Ideas', word.data['activity_ideas'], pdf) if opts[:include_activity_ideas] != false
          # Books: 2 spots per page (with page numbers)
          Progress.update_current_progress(0.5, :adding_books)
          add_books(word.data['books'], false, pdf) if opts[:include_books] != false
            # landscape, 2 per page, all right-side-up, with page numbers
          # Topic Starters: one per page
          Progress.update_current_progress(0.6, :adding_starters)
          add_activities('Topic-Starters', word.data['topic_starters'], pdf) if opts[:include_topic_starters] != false
          # Send-Homes: one per page
          Progress.update_current_progress(0.7, :adding_send_homes)
          add_activities('Send-Homes', word.data['send_homes'], pdf) if opts[:include_send_homes] != false
          # Prompts: two per page
          Progress.update_current_progress(0.8, :adding_prompts)
          add_prompts(word.data['prompts'], pdf) if opts[:include_prompts] != false
            # portrait, 2 per page
        end
        # Videos/Amazon Books: cards, include link
        Progress.update_current_progress(0.9, :adding_links)
        add_links(word, pdf) if opts[:include_links]
        # Attribution and references
        Progress.update_current_progress(0.95, :adding_attribution)
        add_attribution(word, pdf)
      end
    end
    
    path = Tempfile.new('packet').path + ".pdf"
    Progress.update_current_progress(0.95, :rendering_file)
    pdf.render_file(path)
    if opts[:local]
      puts path.to_s
      `open #{path.to_s}`
      sleep 5
    end
    path
  end
  
  def self.new_page(pdf, header=nil, landscape=false)
    @doc_height = 11*72 - 72
    @doc_width = 8.5*72 - 72
    unless @first_page
      if landscape
        pdf.start_new_page(:size => [8.5*72, 11*72], :layout => :landscape)
        @doc_width = 11*72 - 72
        @doc_height = 8.5*72 - 72
      else
        pdf.start_new_page(:size => [8.5*72, 11*72], :layout => :portrait)
        @doc_height = 11*72 - 72
        @doc_width = 8.5*72 - 72
      end
    end
    @first_page = false
    text_height = 12
    pdf.fill_color 'aaaaaa'
    pdf.font_size text_height
    if header
      draw_text pdf, "#{@word.word}: #{header}", :left => -10, :top => @doc_height + 20, :width => @doc_width, :height => text_height
    end
    pdf.fill_color '888888'
    if header != false
      @page += 1
      draw_text pdf, @page.to_s, :left => @doc_width - 20, :top => -5, :width => 40, :height => text_height, :align => :right
      pdf.fill_color 'aaaaaa'
      draw_text pdf, "printed at workshop.openaac.org", :left => 0, :top => -5, :width => @doc_width, :height => text_height, :align => :center
    else
      pdf.fill_color 'aaaaaa'
      draw_text pdf, "printed at workshop.openaac.org", :left => 0, :top => -5, :width => @doc_width, :height => text_height, :align => :left
    end
  end
  
  def self.text_direction(str)
    direction = str.match(rtl_regex) ? :rtl : :ltr
    [str, direction]
  end
  
  def self.word_buttons(word, users)
    buttons = []
    users.each do |user|
      map = user.word_map || {}
      override = (map[word.locale] || {})[word.word]
      if override
        code = Digest::MD5.hexdigest("#{override['image_url']}_#{override['border_color']}_#{override['background_color']}")
        if !buttons.detect{|w| w['code'] == code }
          button = override.dup
          button['code'] = code
          buttons << button
        end
      end
    end
    buttons
  end
  
  def self.add_header(word, users, pdf)
    new_page(pdf)
    buttons = self.word_buttons(word, users)
    if buttons.length == 0
      button = word.data
      button['image_url'] = button['image'] && button['image']['image_url']
      buttons << word.data
    end
    
    # word in big at the top
    pdf.fill_color "000000"
    header_size = 75
    pdf.font_size header_size
    text = word.word
    direction = text_direction(text)
    pdf.text_box text, :at => [0, @doc_height], :width => (@doc_width), :height => header_size, :align => :center, :valign => :center, :overflow => :shrink_to_fit, :direction => direction
    
    # however many buttons are necessary for the listed users, or default if no users defined
    rows = 1
    cols = 1
    if buttons.length <= 1
    elsif buttons.length == 2
      rows = 2
    elsif buttons.length <= 6
      cols = 2
      rows = (buttons.length / 2.0).ceil
    else
      rows = Math.sqrt(buttons.length).ceil
      cols = (buttons.length.to_f / rows).ceil
    end
    button_spacing = [30 / ([rows, cols, 2].max - 1), 10].max
    button_width = ((@doc_width) / cols) - (button_spacing * 0.5 * (cols - 1))
    button_height = ((@doc_height - header_size) / rows) - (button_spacing * 0.5 * (rows - 1))
    text_height = [10, button_height / 10].max
    border_width = [4, text_height / 5].min
    start_x = 0
    start_y = 0
    if buttons.length <= 1
      start_x = 50
      button_width -= 100
      start_y = 100
      button_height -= 200
    elsif buttons.length == 2
      start_x = 100
      button_width -= 200
      start_y = 20
      button_height -= 40
    end
    
    button_radius = button_spacing
    rows.times do |i|
      cols.times do |j|
        button = buttons[(i * cols) + j]
        if button
          x = start_x + (button_width + button_spacing) * j
          y = start_y + (button_height + button_spacing) * (rows - i - 1) + button_height
          pdf.bounding_box([x, y], :width => button_width, :height => button_height) do
            fill = 'ffffff'
            border = 'eeeeee'
            if button['background_color']
              fill = OBF::Utils.fix_color(button['background_color'], 'hex')
            end
            if button['border_color']
              border = OBF::Utils.fix_color(button['border_color'], 'hex')
            end
            pdf.fill_color fill
            pdf.stroke_color border
            pdf.line_width border_width
            pdf.fill_and_stroke_rounded_rectangle [0, button_height], button_width, button_height, button_radius
            
            if button['image_url']
              size = [button_width - (border_width * 2), button_height - text_height - (border_width * 2) - 10].min
              draw_image pdf, button['image_url'], :background => "\##{fill}", :left => (button_width - size) / 2, :top => button_height - text_height - 10, :square => size, :position => :right, :vposition => :bottom
            end
            pdf.fill_color '000000'
            pdf.font_size text_height
            pdf.text_box text, :at => [5, button_height - 5], :width => button_width, :height => text_height, :align => :center, :valign => :center, :overflow => :shrink_to_fit, :direction => direction            
          end
        end
      end
    end
  end
  
  def self.draw_image(pdf, url, opts)
    if url && url.match(/api\/v1\/images/)
      req = Typhoeus.get(url)
      if req.code == 302 && req.headers['Location']
        url = req.headers['Location']
      end
    end
    image_local_path = OBF::Utils.save_image({'url' => url}, nil, opts[:background] || "\#ffffff")
    res = false
    if image_local_path && File.exist?(image_local_path)
      # OBF Utils returns a square image
      size = opts[:square]
      pdf.image image_local_path, :at => [opts[:left], opts[:top]], :fit => [size, size], position: (opts[:position] || :center), vposition: (opts[:vposition] || :center)
      res = true
      if opts[:extract_dominant_color]
        histogram = `convert #{image_local_path} +dither -colors 5 -define histogram:unique-colors=true -format "%c" histogram:info:`
        colors = histogram.split(/\n/).map do |line|
          count = line.split(/:/)[0].strip.to_i
          hex = line.match(/\#(\w+)\s/)[1]
          [count, hex]
        end
        colors = colors.sort_by(&:first).reverse.map(&:last).map do |hex|
          parts = hex.scan(/\w\w/)[0, 3].map{|h| h.hex }
          if parts[0] == parts[1] && parts[1] == parts[2]
            nil
          else
            if ((parts[0] + parts[1] + parts[2]) / 3) > 'aa'.hex
              parts[0] /= 2
              parts[1] /= 2
              parts[2] /= 2
            end
            hex = parts.map{|n| n.to_s(16).rjust(2, '0') }.join
          end
        end
        # sort by count, use the first non-gray color
        res = colors.compact[0] || '888888'
      end
      File.unlink image_local_path
    end
    res
  end
  
  def self.draw_text(pdf, str, opts)
    pdf.text_box str, :at => [(opts[:left] || 5), opts[:top]], :width => (opts[:width] || @doc_width - 10), :height => opts[:height], :align => (opts[:align] || :left), :valign => (opts[:valign] || :center), :overflow => (opts[:overflow] || :shrink_to_fit), :direction => (opts[:direction] || text_direction(str))
  end
  
  def self.add_definitions(word, pdf)
    new_page(pdf)
    text_height = 30
    top = @doc_height
    pdf.font_size text_height
    pdf.fill_color '000000'
    draw_text pdf, word.word, :top => top - text_height, :height => text_height
    top -= text_height + 10
    text_height = 20
    pdf.font_size text_height
    if word.data['parts_of_speech']
      pdf.fill_color 'aaaaaa'
      draw_text pdf, word.data['parts_of_speech'], :top => top - text_height, :height => text_height
      top -= text_height + 5
    end
    if word.data['description']
      pdf.fill_color '000000'
      draw_text pdf, word.data['description'], :top => top - text_height, :height => text_height * 2, :valign => :top
      top -= (text_height * 2) + 15
    end
    if word.data['usage_examples']
      text_height = 20
      pdf.font_size text_height
      pdf.fill_color '000000'
      str = "Usage Examples"
      draw_text pdf, str, :top => top - text_height, :height => text_height
      top -= text_height + 15

      text_height = 12
      pdf.font_size text_height
      word.data['usage_examples'][0, 20].each_with_index do |ex, idx|
        str = "#{idx + 1}. " + (ex['text'] || '').to_s
        draw_text pdf, str, :left => 15, :top => top - text_height, :height => text_height
        top -= text_height + 5
      end
    end
    if WordData::CORE_WORD_PARAMS.any?{|k| word.data[k] }
      text_height = 20
      pdf.font_size text_height
      pdf.fill_color '000000'
      str = "Related Words"
      draw_text pdf, str, :top => top - text_height, :height => text_height
      top -= text_height + 10
      text_height = 14
      pdf.font_size text_height
      WordData::CORE_WORD_PARAMS.each do |param|
        key = param.sub(/_based/, '-based').sub(/_/, ' ')
        left = 150
        pdf.fill_color 'eeeeee'
        pdf.fill_rectangle [5, top - text_height + 2.5], left, text_height + 5
        pdf.fill_color '000000'
        draw_text pdf, key, :left => 10, :top => top - text_height, :width => left, :height => text_height
        text = 'none'
        if word.data[param]
          pdf.fill_color '888888'
          text = word.data[param].gsub(/,(?!\s)/, ', ')
        else
          pdf.fill_color 'aaaaaa'
        end
        draw_text pdf, text, :left => left + 10, :top => top - text_height, :width => @doc_width - left - 10, :height => text_height
        pdf.stroke_color 'cccccc'
        pdf.line_width 1
        pdf.stroke do
          pdf.horizontal_line 5, @doc_width - 10, :at => top - text_height + 2.5
        end
        top -= text_height + 5
      end
    end
  end
  
  def self.add_cards(name, entries, pdf)
    new_page(pdf, name)
    row = 0
    col = 0
    pdf.stroke_color '666666'
    box_width = (@doc_width / 2)
    box_height = (@doc_height / 3) - 20
    entries.each do |entry|
      next unless entry['text'] || entry['sentence']
      if col > 1
        row += 1
        col = 0
        if row > 2
          new_page(pdf, name)
          row = 0
        end
      end
      # draw a bounding box
      x = col * (box_width + 20) - 10
      y = @doc_height - row * (box_height + 20) - 10
      middle = x + 10 + ((box_width - 20) / 2)
      pdf.fill_color 'ffffff'
      pdf.line_width 2
      pdf.fill_and_stroke_rounded_rectangle [x, y], box_width, box_height, 10
      # render the image
      # render the text
      if entry['sentence']
        # entry.text, entry.sentence, entry.image.image_url
        text_height = 30
        pdf.fill_color 'aaaaaa'
        pdf.font_size 13
        draw_text pdf, "model:", :left => x + 10, :top => y - 10, :width => 40, :height => text_height - 5, :valign => :top
        pdf.font_size text_height
        pdf.fill_color '000000'
        draw_text pdf, entry['sentence'], :left => x + 55, :top => y - 1, :width => box_width - 60, :height => text_height, :valign => :bottom
        top = y - text_height
        
        image = (entry['image'] && entry['image']['image_url']) || 'fallback_image'
        if entry['text']
          text_height = 20
          pdf.font_size text_height
          pdf.fill_color '666666'
          height = (box_height - (y - top) - (text_height * 3)) - 10
          draw_image pdf, image, :left => middle - (height / 2), :top => top - 5, :square => height
          draw_text pdf, entry['text'], :left => x + 10, :top => y - box_height + (text_height * 3), :width => box_width - 20, :height => text_height * 3, :valign => :top, :align => :center
        elsif image
          height = (box_height - (y - top)) - 10
          draw_image pdf, image, :left => middle - (height / 2), :top => top - 5, :square => height
        end
      else
        draw_text pdf, entry.to_json, :left => x, :top => y, :width => box_width, :height => box_height
      end
      # advance to the next spot
      col += 1
    end
  end
  
  def self.draw_border(pdf, str, color, left, top, width, height)
    border_type = Digest::MD5.hexdigest(str).hex % 3
    pdf.stroke_color color
    pdf.line_width 2
    if border_type == 0
      pdf.line_width 4
      pdf.stroke_rounded_rectangle [left, top], width, height, 0
    elsif border_type == 1 || true
      twirl = 7
      pdf.stroke_rounded_polygon 3, [left, top], [left, top + twirl], [left - twirl, top + twirl], [left - twirl, top],
        [left + width, top], [left + width + twirl, top], [left + width + twirl, top + twirl], [left + width, top + twirl],
        [left + width, top - height], [left + width, top - height - twirl], [left + width + twirl, top - height - twirl], [left + width + twirl, top - height],
        [left, top - height], [left - twirl, top - height], [left - twirl, top - height - twirl], [left, top - height - twirl], [left, top + twirl]
    else
      pdf.line_width 3
      pdf.stroke_rounded_polygon 20, [left, top], [left + (width / 2), top + 5],
        [left + width, top], [left + width + 5, top - (height / 2)],
        [left + width, top - height], [left + (width / 2), top - height - 5], 
        [left, top - height], [left - 5, top - (height / 2)]
    end
  end
  
  def self.add_books(books, mini, pdf)
    # lookup book by json URL
    books.each do |book|
      json = nil
      if book['book_type'] == 'tarheel'
        json = Book.tarheel_json(book['url'])
      elsif book['book_type'] == 'workshop'
        book_record = Book.find_by_global_id(book['local_id'])
        json = JSON.parse(book_record.book_json)
      else
        # API call to "#{JsonApi::Json.current_host}/api/v1/books/json?url=#{book['url']}"
      end
      book_font = File.expand_path('../../public/fonts/ArchitectsDaughter.ttf', __FILE__)
      if json
        attributions = []
        new_page(pdf, false, true)
        # title, author, image with border
        image_url = json['image_url'] || json['pages'][0]['image_url']
        page_pad = 10
        page_width = (@doc_width / 2) - (page_pad * 6)
        first_left = page_pad
        second_left = (@doc_width / 2) + (page_pad * 3)
        pdf.font_size 15
        pdf.fill_color '888888'
        instr = ["#{json['title']}\nAssembly Instructions:"]
        instr << "This book prints two pages per sheet. This sheet is the cover and can be folded in half with the pictures and text on the outside and added at the end. These instructions should end up on the back of the book."
        instr << "For the rest of the pages, fold them in half with pictures and text on the inside. Stack the folded pages on top of each other in the order they were printed. You can glue or tape the blank sides together or leave them as-is and just flip twice for each page turn."
        instr << "Finally, after adding the cover, staple or bind the pages together to complete the book."
        instr << "Read and enjoy!"
        draw_text pdf, instr.join("\n\n"), :left => first_left, :top => @doc_height - page_pad, :width => page_width, :height => @doc_height - (page_pad * 2), :valign => :top, :align => :left
        text_height = 50
        pdf.font_size text_height
        pdf.fill_color '000000'
        top = @doc_height - page_pad
        draw_text pdf, json['title'], :left => second_left, :top => top, :width => page_width, :height => text_height * 2, :valign => :top, :align => :center
        top -= text_height * 2 + 10
        if image_url
          dom_color = draw_image pdf, image_url, :left => second_left + 10, :top => top - 10, :square => page_width - 20, :extract_dominant_color => true
          if dom_color
            draw_border(pdf, image_url, dom_color, second_left, top, page_width, page_width)
          end
        end
        top -= page_width + 20
        text_height = 20
        pdf.font_size text_height
        pdf.fill_color '888888'
        draw_text pdf, "by #{json['author']}", :left => second_left, :top => top, :width => page_width, :height => text_height * 2, :valign => :top, :align => :center
        column = 0
        page_number = 0
        json['pages'].each do |page|
          next if page['id'] == 'title_page'
          page_number += 1
          # draw page
          # if image is not defined, use the full space for text
          new_page(pdf, false, true) if column == 0
          left = column == 0 ? first_left : second_left
          top = @doc_height - page_pad
          if page['image_url']
            if page['image_attribution_type']
              attributions << {
                'type' => page['image_attribution_type'],
                'author' => page['image_attribution_author'],
                'url' => page['image_attribution_url']
              }
            end
            if page['image2_url']
              square = (page_width / 2) - page_pad
              draw_image pdf, page['image_url'], :left => left, :top => top - (square / 2), :square => square
              draw_image pdf, page['image2_url'], :left => left + (page_width / 2) + page_pad, :top => top - (square / 2), :square => square
              top -= square + 20
              if page['image2_attribution_type']
                attributions << {
                  'type' => page['image2_attribution_type'],
                  'author' => page['image2_attribution_author'],
                  'url' => page['image2_attribution_url']
                }
              end
            else
              draw_image pdf, page['image_url'], :left => left, :top => top, :square => page_width
              top -= page_width + 20
            end
          end
          pdf.font(book_font) do
            pdf.font_size 30
            pdf.fill_color '000000'
            draw_text pdf, page['text'], :left => left, :top => top, :width => page_width, :height => (@doc_height - top), :valign => :middle, :align => :center
          end
          pdf.fill_color 'FFFFFF'
          pdf.stroke_color 'aaaaaa'
          pdf.line_width 2
          pdf.circle [left + page_width - 15, 7.5], 20
          pdf.stroke
          pdf.font_size 15
          pdf.fill_color '888888'
          draw_text pdf, page_number.to_s, :left => left + page_width - 30, :top => 15, :width => 30, :height => 15, :valign => :bottom, :align => :center
          
          column = (column + 1) % 2
        end
        # attributions on the right side
        new_page(pdf, false, true) unless column == 1
        authors = attributions.uniq.map do |attr|
          "#{attr['type']} by #{attr['author']}\n#{Prawn::Text::NBSP*5}#{attr['url']}"
        end
        pdf.font_size 20
        pdf.fill_color '888888'
        draw_text pdf, "Attributions:", :left => (@doc_width / 2) + page_pad, :top => @doc_height - page_pad, :width => (@doc_width / 2) - (page_pad * 2), :height => 20, :valign => :top, :align => :left
        authors = []
        authors << "Text by #{json['author']}\n#{Prawn::Text::NBSP*5}#{json['book_url']}" if json['book_url']
        authors << "General Image Attribution\n#{Prawn::Text::NBSP*5}#{json['attribution_url']}" if json['attribution_url']
        authors += attributions.map do |img|
          "#{img['license']} by #{img['author']}\n#{Prawn::Text::NBSP*5}#{img['author_url']}"
        end
        authors << "\nprinted #{Date.today.to_s}"
        pdf.font_size 14
        draw_text pdf, authors.join("\n"), :left => (@doc_width / 2) + page_pad, :top => @doc_height - page_pad - 20, :width => (@doc_width / 2) - (page_pad * 2), :height => @doc_height, :valign => :top, :align => :left

      end
    end
  end
  
  def self.add_activities(name, entries, pdf)
    return unless entries.length > 0
    entries.each do |entry|
      new_page(pdf, name)
      top = @doc_height - 20
      text_height = 50
      pdf.font_size text_height
      pdf.fill_color '000000'
      draw_text pdf, entry['text'] || 'activity', :left => 0, :width => @doc_width, :top => top, :height => text_height, :align => :center, :valign => :top
      top -= text_height + 30
      image = (entry['image'] && entry['image']['image_url']) || 'fallback_image'
      image_size = 400
      if image
        draw_image pdf, image, :left => (@doc_width / 2) - (image_size / 2), :top => top, :square => image_size
      end
      top -= image_size
      if entry['description']
        pdf.font_size 30
        pdf.fill_color '444444'
        draw_text pdf, entry['description'], :left => 0, :width => @doc_width, :top => top, :height => top, :align => :center, :valign => :middle
      end
    end
  end
  
  def self.add_prompts(prompts, pdf)
    return if !prompts || prompts.length == 0
    new_page(pdf, "Prompts")
    row = 0
    pdf.stroke_color '666666'
    box_width = @doc_width
    box_height = (@doc_height / 2) - 20
    prompts.each do |entry|
      next unless entry['text'] || entry['sentence']
      if row > 1
        row = 0
        new_page(pdf, "Prompts")
      end
      # draw a bounding box
      x = 0 * (box_width + 20) - 10
      y = @doc_height - row * (box_height + 20) - 10
      middle = x + 10 + ((box_width - 20) / 2)
      pdf.fill_color 'ffffff'
      pdf.line_width 2
      pdf.fill_and_stroke_rounded_rectangle [x, y], box_width, box_height, 10
      # render the image
      # render the text

      # entry.text, entry.sentence, entry.image.image_url
      text_height = 30
      pdf.fill_color 'aaaaaa'
      pdf.font_size 13
      draw_text pdf, (entry['prompt_type'] == 'open_ended') ? "prompt:" : "fill in the blank:", :left => x + 10, :top => y - 10, :width => @doc_width, :height => text_height - 5, :valign => :top
      pdf.font_size text_height
      pdf.fill_color '000000'
      top = y - text_height
      
      image = (entry['image'] && entry['image']['image_url']) || 'fallback_image'
      text_height = 20
      pdf.font_size text_height
      pdf.fill_color '444444'
      height = (box_height - (y - top) - (text_height * 3)) - 10
      draw_image pdf, image, :left => middle - (height / 2), :top => top - 5, :square => height
      draw_text pdf, entry['text'], :left => x + 10, :top => y - box_height + (text_height * 3), :width => box_width - 20, :height => text_height * 3, :valign => :center, :align => :center

      # advance to the next spot
      row += 1
    end
  end
  
  def self.add_links(workd, pdf)
  end

  def self.add_attribution(word, pdf)
    new_page(pdf, "Attribution")
    top = @doc_height
    text_height = 30
    pdf.font_size text_height
    pdf.fill_color '000000'
    draw_text pdf, "Authors", :left => 10, :top => top, :height => text_height, :width => @doc_width - 20
    top -= text_height + 10
    authors = ["CoughDrop, Inc."]
    text_height = 20
    pdf.font_size text_height
    pdf.fill_color '444444'
    draw_text pdf, authors.join(', '), :left => 30, :top => top, :height => text_height * 2, :width => @doc_width - 40, :valign => :top
    
    top -= (text_height * 2) + 10
    text_height = 30
    pdf.font_size text_height
    pdf.fill_color '000000'
    draw_text pdf, "Image Attributions", :left => 10, :top => top, :height => text_height, :width => @doc_width - 20
#    raise "include button image attributions"
    top -= text_height + 10
    images = []
    word.data.keys.each do |key|
      if word.data[key].is_a?(Array)
        word.data[key].each do |hash|
          if hash['image']
            images << hash['image']
          end
        end
      elsif word.data[key].is_a?(Hash)
        if word.data[key]['image']
          images << word.data[key]['image']
        end
      end
    end
    authors = images.map do |img|
      "#{img['license']} by #{img['author']}\n#{Prawn::Text::NBSP*5}#{img['author_url']}"
    end
    authors << "\nprinted #{Date.today.to_s}"
    text_height = 15
    pdf.fill_color '444444'
    pdf.font_size text_height
    draw_text pdf, authors.uniq.join("\n"), :left => 30, :top => top, :height => top, :width => @doc_width - 40, :valign => :top
  end  
end

