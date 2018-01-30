require 'prawn'

module PacketMaker
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

    words.each do |word|
      # TODO: Options to exclude topic areas, or to only include entries with matching ids
      # (i.e. to print an individual book)
    
      # Header page should show all versions of the icons for matched users
      add_header(word, users, pdf) if opts[:include_header] != false
      # Definition page: definition, bulleted usage examples, related core words
      add_definitions(word, pdf) if opts[:include_definition] != false

      # Modeling page: tiles/cutouts with image phrase, explanation if any
      add_cards('Modeling Examples', word.data['level_1_modeling_examples'], pdf) if opts[:include_modeling] != false

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
        add_cards('Activities', entries, pdf)

        # Books: 4 spots per page (with page numbers)
        add_books(word.data['books'], true, pdf) if opts[:include_books] != false
          # portrait, 4 per page, foldable (upside-down to match) with page numbers
          # include The End page with attributions
      # Verbose version:
      else
        # Learning projects: one per page
        add_activities('Learning Projects', word.data['learning_projects'], pdf) if opts[:include_learning_projects] != false
        # Activity ideas: one per page
        add_activities('Activity Ideas', word.data['activity_ideas'], pdf) if opts[:include_activity_ideas] != false
        # Books: 2 spots per page (with page numbers)
        add_books(word.data['books'], false, pdf) if opts[:include_books] != false
          # landscape, 2 per page, all right-side-up, with page numbers
        # Topic Starters: one per page
        add_activities('Topic-Starters', word.data['topic_starters'], pdf) if opts[:include_topic_starters] != false
        # Send-Homes: one per page
        add_activities('Send-Homes', word.data['send_homes'], pdf) if opts[:include_send_homes] != false
        # Prompts: two per page
        add_prompts(word.data['prompts'], pdf) if opts[:include_prompts] != false
          # portrait, 2 per page
      end
      # Videos/Amazon Books: cards, include link
      add_links(word, pdf) if opts[:include_links]
      # Attribution and references
      add_attribution(word, pdf)
    end
    
    pdf.render_file("./test.pdf")
    `open ./test.pdf`
  end
  
  def self.new_page(pdf, header=nil)
    pdf.start_new_page unless @first_page
    @first_page = false
    @doc_height = 11*72 - 72
    @doc_width = 8.5*72 - 72
    raise "header not defined" if header
  end
  
  def self.text_direction(str)
    direction = str.match(rtl_regex) ? :rtl : :ltr
    [str, direction]
  end
  
  def self.add_header(word, users, pdf)
    new_page(pdf)
    buttons = []
    users.each do |user|
      map = user.word_map
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
    if buttons.length == 0
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
              image_local_path = OBF::Utils.save_image({'url' => button['image_url']}, nil, "\##{fill}")
              if image_local_path && File.exist?(image_local_path)
                pdf.fill_color 'eeeeee'
                pdf.stroke_color '000000'
                # OBF Utils returns a square image
                size = [button_width - 10, button_height - text_height - 15].min
                pdf.image image_local_path, :at => [(button_width - size) / 2, button_height - text_height - 10], :fit => [size, size], position: :right, vposition: :bottom
                File.unlink image_local_path
              end
            end
            pdf.fill_color '000000'
            pdf.font_size text_height
            pdf.text_box text, :at => [5, button_height - 5], :width => button_width, :height => text_height, :align => :center, :valign => :center, :overflow => :shrink_to_fit, :direction => direction            
          end
        end
      end
    end
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
    new_page(pdf)
    row = 0
    col = 0
    (entries * 5).each do |entry|
      if col > 1
        row += 1
        col = 0
        if row > 2
          new_page(pdf)
          row = 0
        end
      end
      # draw a bounding box
      x = col * (@doc_width / 2) + 10
      y = @doc_height - row * (@doc_height / 3) + 10
      pdf.fill_color 'ffffff'
      pdf.line_width 2
      pdf.fill_and_stroke_rounded_rectangle [x, y], (@doc_width / 2) - 20, (@doc_height / 3) - 20, 10
      # render the image
      # advance to the next spot
      col += 1
    end
  end
  
  def self.add_books(books, mini, pdf)
  end
  
  def self.add_activities(name, entries, pdf)
  end
  
  def self.add_prompts(prompts, pdf)
  end
  
  def self.add_links(workd, pdf)
  end

  def self.add_attribution(word, pdf)
  end  
end


# 
# module OBF::PDF
#   @@footer_text ||= nil
#   @@footer_url ||= nil
#   
#   RTL_SCRIPTS = %w(Arabic Hebrew Nko Kharoshthi Phoenician Syriac Thaana Tifinagh)
#   
#   def self.footer_text
#     @@footer_text
#   end
#   
#   def self.footer_text=(text)
#     @@footer_text = text
#   end
# 
#   def self.footer_url
#     @@footer_url
#   end
#   
#   def self.footer_url=(url)
#     @@footer_url = url
#   end
#   
#   def self.from_obf(obf_json_or_path, dest_path, zipper=nil, opts={})
#     obj = obf_json_or_path
#     if obj.is_a?(String)
#       obj = OBF::Utils.parse_obf(File.read(obf_json_or_path))
#     else
#       obj = OBF::Utils.parse_obf(obf_json_or_path)
#     end
#     build_pdf(obj, dest_path, zipper, opts)
#     return dest_path
#   end
#   
#   def self.build_pdf(obj, dest_path, zipper, opts={})
#     OBF::Utils.as_progress_percent(0, 1.0) do
#       # parse obf, draw as pdf
#       pdf = Prawn::Document.new(
#         :page_layout => :landscape, 
#         :page_size => [8.5*72, 11*72],
#         :info => {
#           :Title => obj['name']
#         }
#       )
#       font = opts['font'] if opts['font'] && File.exists?(opts['font'])
#       font ||= File.expand_path('../../TimesNewRoman.ttf', __FILE__)
#       pdf.font(font) if File.exists?(font)
#     
#     
#       if obj['boards']
#         obj['boards'].each_with_index do |board, idx|
#           pre = idx.to_f / obj['boards'].length.to_f
#           post = (idx + 1).to_f / obj['boards'].length.to_f
#           OBF::Utils.as_progress_percent(pre, post) do
#             pdf.start_new_page unless idx == 0
#             build_page(pdf, board, {
#               'zipper' => zipper, 
#               'pages' => obj['pages'], 
#               'headerless' => !!opts['headerless'], 
#               'font' => font,
#               'text_on_top' => !!opts['text_on_top'], 
#               'transparent_background' => !!opts['transparent_background'],
#               'text_case' => opts['text_case']
#             })
#           end
#         end
#       else
#         build_page(pdf, obj, {
#           'headerless' => !!opts['headerless'], 
#           'font' => font,
#           'text_on_top' => !!opts['text_on_top'], 
#           'transparent_background' => !!opts['transparent_background'],
#           'text_case' => opts['text_case']
#         })
#       end
#     
#       pdf.render_file(dest_path)
#     end
#   end
#   
#   def self.rtl_regex
#     @res ||= /[#{RTL_SCRIPTS.map{ |script| "\\p{#{script}}" }.join}]/
#   end
#   
#   def self.build_page(pdf, obj, options)
#     OBF::Utils.as_progress_percent(0, 1.0) do
#       pdf.font(options['font']) if options['font'] && File.exists?(options['font'])
#       doc_width = 11*72 - 72
#       doc_height = 8.5*72 - 72
#       default_radius = 3
#       text_height = 20
#       header_height = 0
#     
#       if options['pages']
#         page_num = options['pages'][obj['id']]
#         pdf.add_dest("page#{page_num}", pdf.dest_fit)
#       end
#       # header
#       if !options['headerless']
#         header_height = 100
#         pdf.bounding_box([0, doc_height], :width => doc_width, :height => 100) do
#           pdf.line_width = 2
#           pdf.font_size 16
#         
#           pdf.fill_color "eeeeee"
#           pdf.stroke_color "888888"
#           pdf.fill_and_stroke_rounded_rectangle [0, 100], 100, 100, default_radius
#           pdf.fill_color "6D81D1"
#           pdf.fill_and_stroke_polygon([5, 50], [35, 85], [35, 70], [95, 70], [95, 30], [35, 30], [35, 15])
#           pdf.fill_color "ffffff"
#           pdf.formatted_text_box [{:text => "Go Back", :anchor => "page1"}], :at => [10, 90], :width => 80, :height => 80, :align => :center, :valign => :center, :overflow => :shrink_to_fit
#           pdf.fill_color "ffffff"
#           pdf.fill_and_stroke_rounded_rectangle [110, 100], (doc_width - 200 - 20), 100, default_radius
#           pdf.fill_color "DDDB54"
#           pdf.fill_and_stroke do
#             pdf.move_to 160, 50
#             pdf.line_to 190, 70
#             pdf.curve_to [190, 30], :bounds => [[100, 130], [100, -30]]
#             pdf.line_to 160, 50
#           end
#           pdf.fill_color "444444"
#           pdf.text_box "Say that sentence out loud for me", :at => [210, 90], :width => (doc_width - 200 - 120), :height => 80, :align => :left, :valign => :center, :overflow => :shrink_to_fit
#           pdf.fill_color "eeeeee"
#           pdf.fill_and_stroke_rounded_rectangle [(doc_width - 100), 100], 100, 100, default_radius
#           pdf.fill_color "aaaaaa"
#           pdf.fill_and_stroke_polygon([doc_width - 100 + 5, 50], [doc_width - 100 + 35, 85], [doc_width - 100 + 95, 85], [doc_width - 100 + 95, 15], [doc_width - 100 + 35, 15])
#           pdf.fill_color "ffffff"
#           pdf.text_box "Erase", :at => [(doc_width - 100 + 10), 90], :width => 80, :height => 80, :align => :center, :valign => :center, :overflow => :shrink_to_fit
#         end
#       end
#     
#       # board
#       pdf.font_size 12
#       padding = 10
#       grid_height = doc_height - header_height - text_height - (padding * 2)
#       grid_width = doc_width
#       if obj['grid'] && obj['grid']['rows'] > 0 && obj['grid']['columns'] > 0
#         button_height = (grid_height - (padding * (obj['grid']['rows'] - 1))) / obj['grid']['rows'].to_f
#         button_width = (grid_width - (padding * (obj['grid']['columns'] - 1))) / obj['grid']['columns'].to_f
#         obj['grid']['order'].each_with_index do |buttons, row|
#           buttons.each_with_index do |button_id, col|
#             button = obj['buttons'].detect{|b| b['id'] == button_id }
#             next if !button || button['hidden'] == true
#             x = (padding * col) + (col * button_width)
#             y = text_height + padding - (padding * row) + grid_height - (row * button_height)
#             pdf.bounding_box([x, y], :width => button_width, :height => button_height) do
#               fill = "ffffff"
#               border = "eeeeee"
#               if button['background_color']
#                 fill = OBF::Utils.fix_color(button['background_color'], 'hex')
#               end   
#               if button['border_color']
#                 border = OBF::Utils.fix_color(button['border_color'], 'hex')
#               end         
#               pdf.fill_color fill
#               pdf.stroke_color border
#               pdf.fill_and_stroke_rounded_rectangle [0, button_height], button_width, button_height, default_radius
#               vertical = options['text_on_top'] ? button_height - text_height : button_height - 5
# 
#               text = (button['label'] || button['vocalization']).to_s
#               direction = text.match(rtl_regex) ? :rtl : :ltr
#               if options['text_case'] == 'upper'
#                 text = text.upcase
#               elsif options['text_case'] == 'lower'
#                 text = text.downcase
#               end
#               
#               if options['text_only']
#                 # render text
#                 pdf.fill_color "000000"
#                 pdf.text_box text, :at => [0, 0], :width => button_width, :height => button_height, :align => :center, :valign => :center, :overflow => :shrink_to_fit, :direction => direction
#               else
#                 # render image
#                 pdf.bounding_box([5, vertical], :width => button_width - 10, :height => button_height - text_height - 5) do
#                   image = (obj['images_hash'] || {})[button['image_id']]
#                   if image
#                     bg = 'white'
#                     if options['transparent_background']
#                       bg = "\##{fill}"
#                     end
#                     image_local_path = image && OBF::Utils.save_image(image, options['zipper'], bg)
#                     if image_local_path && File.exist?(image_local_path)
#                       pdf.image image_local_path, :fit => [button_width - 10, button_height - text_height - 5], :position => :center, :vposition => :center
#                       File.unlink image_local_path
#                     end
#                   end
#                 end
#                 if options['pages'] && button['load_board']
#                   page = options['pages'][button['load_board']['id']]
#                   if page
#                     page_vertical = options['text_on_top'] ? -2 + text_height : button_height + 2
#                     pdf.fill_color "ffffff"            
#                     pdf.stroke_color "eeeeee"            
#                     pdf.fill_and_stroke_rounded_rectangle [button_width - 18, page_vertical], 20, text_height, 5
#                     pdf.fill_color "000000"
#                     pdf.formatted_text_box [{:text => page, :anchor => "page#{page}"}], :at => [button_width - 18, page_vertical], :width => 20, :height => text_height, :align => :center, :valign => :center
#                   end
#                 end
#               
#                 # render text
#                 pdf.fill_color "000000"
#                 vertical = options['text_on_top'] ? button_height : text_height
#                 pdf.text_box text, :at => [0, vertical], :width => button_width, :height => text_height, :align => :center, :valign => :center, :overflow => :shrink_to_fit, :direction => direction
#               end
#             end
#             index = col + (row * obj['grid']['columns'])
#             OBF::Utils.update_current_progress(index.to_f / (obj['grid']['rows'] * obj['grid']['columns']).to_f)
#           end
#         end
#       end
#     
#       # footer
#       pdf.fill_color "aaaaaa"
#       if OBF::PDF.footer_text
#         text = OBF::PDF.footer_text
#         pdf.formatted_text_box [{:text => text, :link => OBF::PDF.footer_url}], :at => [doc_width - 300, text_height], :width => 200, :height => text_height, :align => :right, :valign => :center, :overflow => :shrink_to_fit
#       end
#       pdf.fill_color "000000"
#       if options['pages']
#         pdf.formatted_text_box [{:text => options['pages'][obj['id']], :anchor => "page1"}], :at => [doc_width - 100, text_height], :width => 100, :height => text_height, :align => :right, :valign => :center, :overflow => :shrink_to_fit
#       end
#     end
#   end
#   
#   def self.from_obz(obz_path, dest_path, opts={})
#     OBF::Utils.load_zip(obz_path) do |zipper|
#       manifest = JSON.parse(zipper.read('manifest.json'))
#       root = manifest['root']
#       board = OBF::Utils.parse_obf(zipper.read(root))
#       board['path'] = root
#       unvisited_boards = [board]
#       visited_boards = []
#       while unvisited_boards.length > 0
#         board = unvisited_boards.shift
#         visited_boards << board
#         children = []
#         board['buttons'].each do |button|
#           if button['load_board']
#             children << button['load_board']
#             all_boards = visited_boards + unvisited_boards
#             if all_boards.none?{|b| b['id'] == button['load_board']['id'] || b['path'] == button['load_board']['path'] }
#               path = button['load_board']['path'] || (manifest['paths'] && manifest['paths']['boards'] && manifest['paths']['boards'][button['load_board']['id']])
#               if path
#                 b = OBF::Utils.parse_obf(zipper.read(path))
#                 b['path'] = path
#                 button['load_board']['id'] = b['id']
#                 unvisited_boards << b
#               end
#             end
#           end
#         end
#       end
#       
#       pages = {}
#       visited_boards.each_with_index do |board, idx|
#         pages[board['id']] = (idx + 1).to_s
#       end
#       
#       build_pdf({
#         'name' => 'Communication Board Set',
#         'boards' => visited_boards,
#         'pages' => pages
#       }, dest_path, zipper, opts)
#     end
#     # parse obz, draw as pdf
# 
#     # TODO: helper files included at the end for emergencies (eg. body parts)
#     
#     return dest_path
#   end
#   
#   def self.from_external(content, dest_path)
#     tmp_path = OBF::Utils.temp_path("stash")
#     if content['boards']
#       from_obz(OBF::OBZ.from_external(content, tmp_path), dest_path)
#     else
#       from_obf(OBF::OBF.from_external(content, tmp_path), dest_path)
#     end
#     File.unlink(tmp_path) if File.exist?(tmp_path)
#     dest_path
#   end
#   
#   def self.to_png(pdf, dest_path)
#     OBF::PNG.from_pdf(pdf, dest_path)
#   end
# end