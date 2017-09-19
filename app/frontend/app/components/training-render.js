import Ember from 'ember';
import i18n from '../utils/i18n';

export default Ember.Component.extend({
  willInsertElement: function() {
    this.setup();

    var listener = function(event) {
      if(event.data && event.data.type == 'aac_event') {
        var buttons = _this.get('buttons') || [];
        buttons.push(event.data);
        _this.set('buttons', [].concat(buttons));
      }
    };
    window.addEventListener('message', listener);
    this.set('listener', listener);
  },
  setup: function() {
    var _this = this;
    this.set('current_index', 0);
    var rules = this.get('rules') || '';
    var lines = rules.split(/\n/);
    var header = "";
    var image = "";
    var prompt = "";
    var sequence = [];
    var activities = [];
    var board = "https://app.mycoughdrop.com/example/core-24";
    var any_line = false;
    lines.forEach(function(line) {
      if(line.match(/^\s*\*.+\*\s*$/)) {
        // *Header Text*
        header = line.replace(/^\s*\*+\s*/, '').replace(/\s*\*\s*$/, '');
        any_line = true;
      } else if(line.match(/\s*\[.+\]\s*/)) {
        // [http://www.example.com/image.png]
        if(!any_line) {
          board = line.replace(/^\s*\[\s*/, '').replace(/\s*\]\s*$/, '');
          any_line = true;
        } else {
          image = line.replace(/^\s*\[\s*/, '').replace(/\s*\]\s*$/, '');
        }
      } else if(line.match(/\s*\{.+\}\s*/)) {
        // {I|you,want|like|need,help}
        var parts = line.replace(/^\s*\{\s*/, '').replace(/\s*\}\s*$/, '');
        any_line = true;
        sequence = [];
        var chunks = parts.split(',');
        chunks.forEach(function(chunk) {
          var words = chunk.split(/\|/);
          sequence.push(words);
        });
        activities.push({
          sequence: sequence,
          header: header,
          image: image,
          prompt: prompt
        });
        header = null;
        image = null;
        prompt = "";
      } else if(line.match(/[^\s]/)) {
        any_line = true;
        prompt = prompt + line + "\n\n";
      }
    });
    if(board && !board.match(/embed/)) {
      board = board + "?embed=1";
    }
    this.set('url', board);
    if(prompt) {
      activities.push({
        header: header,
        image: image,
        prompt: prompt
      });
    }
    this.set('activities', activities);
  },
  reset_on_change: function() {
    if(this.get('reset_id')) {
      this.setup();
    }
  }.observes('reset_id'),
  check_activity: function() {
    if(this.get('buttons') && this.get('current_activity.sequence.length')) {
      var buttons = this.get('buttons') || [];
      var sequence = this.get('current_activity.sequence');
      var sequence_idx = 0;
      var sequence_met = false;
      buttons.forEach(function(button) {
        var unit = sequence[sequence_idx];
        var unit_met = false;
        if(unit) {
          unit.forEach(function(word) {
            var re = new RegExp(word, 'i');
            if(button.text.match(re) || word == '') {
              unit_met = true;
            }
          });
        }
        if(unit_met) {
          sequence_idx++;
          if(sequence_idx >= sequence.length) {
            sequence_met = true;
          }
        }
      });
      if(sequence_met) {
        this.set('current_index', (this.get('current_index') || 0) + 1);
        this.set('buttons', null);
      }
    }
  }.observes('current_activity', 'buttons', 'buttons.length'),
  willDestroyElement: function() {
    window.removeEventListener('message', this.get('listener'));
    this.set('listener', null);
  },
  current_activity: function() {
    if(this.get('activities')) {
      return this.get('activities')[this.get('current_index') || 0];
    } else {
      return null;
    }
  }.property('current_index', 'activities'),
  actions: {
  }
});
