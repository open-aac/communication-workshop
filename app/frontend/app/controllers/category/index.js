import Ember from 'ember';
import modal from '../../utils/modal';
import i18n from '../../utils/i18n';

export default Ember.Controller.extend({
  image_style: function() {
    var css = "width: 100px; padding: 10px; max-height: 100px; border-width: 3px; border-radius: 5px; border-style: solid;";
    var border = this.get('model.border_color') || '#888';
    var background = this.get('model.background_color') || '#fff';
    css = css + "border-color: " + border + ";";
    css = css + "background-color: " + background + ";";
    return Ember.String.htmlSafe(css);
  }.property('model.border_color', 'model.background_color'),
  current_level: function() {
    var num = this.get('modeling_level') || 1;
    var desc = i18n.t('one_button', "1-button communicators");
    if(num === 2) {
      desc = i18n.t('two_button', "2-3 button communicators");
    } else if(num === 3) {
      desc = i18n.t('three_plus_button', ">3-button communicators");
    }
    var level = {
      modeling_examples: this.get('model.level_' + num + '_modeling_examples'),
      level: num,
      description: desc
    };
    level['level_' + num] = true;
    return level;
  }.property('modeling_level', 'model.id'),
  current_activity: function() {
    var activity = this.get('activity') || 'activities';
    var res = {
      type: activity,
      list: this.get('model.' + activity)
    };
    res[activity] = true;
    return res;
  }.property('activity', 'model.id'),
  actions: {
    update_image: function(image, key) {
      if(!key || key == 'image') {
        this.set('model.image', image);
      }
    },
    save: function() {
      var model = this.get('model');
      var _this = this;
      _this.set('status', {saving: true});
      model.save().then(function() {
        _this.set('status', null);
        _this.set('editing', false);
      }, function(err) {
        _this.set('status', {error: true});
      });
    },
    set_level: function(level) {
      this.set('modeling_level', level);
    },
    set_activity: function(activity) {
      this.set('activity', activity);
    },
    edit: function() {
      this.set('editing', true);
    },
    cancel: function() {
      this.get('model').rollbackAttributes();
      this.set('editing', false);
    }
  }
});
