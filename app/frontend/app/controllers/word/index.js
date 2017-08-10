import Ember from 'ember';
import modal from '../../utils/modal';
import i18n from '../../utils/i18n';

export default Ember.Controller.extend({
  button: function() {
    return {
      background_color: this.get('model.background_color'),
      border_color: this.get('model.border_color'),
      label: this.get('model.word'),
      image_url: this.get('model.image.image_url'),
      id: this.get('model.id')
    };
  }.property('model.id', 'model.word', 'model.image', 'model.border_color', 'model.background_color'),
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
    var activity = this.get('activity') || 'learning_projects';
    var res = {
      type: activity,
      list: this.get('model.' + activity)
    };
    res[activity] = true;
    return res;
  }.property('activity', 'model.id'),
  actions: {
    update_image: function(image, key) {
      if(!key || key === 'image') {
        this.set('model.image', image);
      }
    },
    save: function() {
      var model = this.get('model');
      var _this = this;
      _this.set('status', {saving: true});
      if(this.get('revision.id')) {
        model.set('clear_revision_id', this.get('revision.id'));
      }
      model.save().then(function() {
        _this.set('status', null);
        _this.set('editing', false);
      }, function(err) {
        _this.set('status', {error: true});
      });
    },
    save_with_credit: function() {
      this.set('model.revision_credit', this.get('revision.user_identifier'));
      this.send('save');
    },
    set_level: function(level) {
      this.set('modeling_level', level);
    },
    set_activity: function(activity) {
      this.set('activity', activity);
    },
    edit: function() {
      this.set('editing', true);
      this.set('model.revision_credit', null);
      this.set('revision', null);
    },
    cancel: function() {
      this.get('model').rollbackAttributes();
      this.set('model.revision_credit', null);
      this.set('editing', false);
      this.set('revision', null);
    },
    set_revision: function(rev) {
      this.set('editing', true);
      this.set('model.revision_credit', null);
      this.set('revision', JSON.parse(JSON.stringify(rev)));
    },
    accept_revision: function(attr) {
      if(this.get('revision.changes.' + attr)) {
        this.set('model.' + attr, this.get('revision.changes.' + attr));
        this.set('revision.changes.' + attr, null);
      }
    },
    update_revision_object: function(entry, attr) {
      var list = this.get('model.' + attr) || [];
      if(entry.action == 'update') {
        if(entry.id) {
          var o = list.find(function(i) { return i.id == entry.id; });
          var idx = list.indexOf(o);
          if(idx >= 0) {
            list.replace(idx, 1, [entry]);
          }
        }
      } else if(entry.action == 'delete') {
        if(entry.id) {
          var o = list.find(function(i) { return i.id == entry.id; });
          if(o) {
            list.removeObject(o);
          }
        }
      } else {
        list.pushObject(entry);
      }
      delete entry[attr];
      (this.get('revision.changes.' + attr) || []).removeObject(entry);
    }
  }
});
