import Ember from 'ember';
import modal from '../utils/modal';
import i18n from '../utils/i18n';

export default Ember.Controller.extend({
  clear_on_change: function() {
    this.set('current_index', 0);
  }.property('model.pages', 'model.id'),
  current_page: function() {
    var index = this.get('current_index') || 0;
    if(index === 0) {
      this.set('model.title_page', true);
      return this.get('model');
    } else {
      return (this.get('model.pages') || [])[index - 1];
    }
  }.property('model.pages', 'model.pages.length', 'current_index'),
  readable_index: function() {
    return (this.get('current_index') || 0);
  }.property('current_index'),
  update_1: function() {
    if(this.get('editing')) {
      return 'update_image_1';
    } else {
      return null;
    }
  }.property('editing'),
  update_2: function() {
    if(this.get('editing')) {
      return 'update_image_2';
    } else {
      return null;
    }
  }.property('editing'),
  no_prev: function() {
    return (this.get('current_index') || 0) === 0;
  }.property('current_index'),
  no_next: function() {
    return (this.get('current_index') || 0) >= this.get('model.pages.length');
  }.property('current_index', 'model.pages.length'),
  single_image: function() {
    return !this.get('current_page.extra_image');
  }.property('current_page.extra_image'),
  editable: function() {
    return this.get('model.pending') || this.get('editing') || true;
  }.property('model.pending'),
  actions: {
    edit: function() {
      this.set('editing', true);
    },
    save: function() {
      var _this = this;
      _this.set('status', {saving: true});
      _this.get('model').save().then(function() {
        _this.set('status', null);
        _this.set('editing', false);
      }, function() {
        _this.set('status', {error: true});
      });
    },
    cancel: function() {
      if(this.get('model.pending')) {
        this.transitionToRoute('index');
      } else {
        this.get('model').rollbackAttributes();
        this.set('editing', false);
      }
    },
    previous: function() {
      var idx = this.get('current_index') || 0;
      this.set('current_index', Math.max(idx - 1, 0));
    },
    delete_current: function() {
      var entries = (this.get('model.pages') || []);
      var current_index = (this.get('current_index') || 0) - 1;
      var res = [];
      entries.forEach(function(e, idx) {
        if(idx !== current_index) {
          res.push(e);
        }
      });
      this.set('model.pages', res);
      if(current_index > res.length) {
        this.set('current_index', res.length);
      }
    },
    next: function() {
      var idx = this.get('current_index') || 0;
      this.set('current_index', Math.min(idx + 1, (this.get('model.pages') || []).length));
    },
    add: function() {
      this.get('model.pages').pushObject({});
      this.set('current_index', this.get('model.pages').length);
    },
    update_image_1: function(image) {
      var entry = this.get('current_page');
      if(entry) {
        Ember.set(entry, 'image', image);
      }
    },
    update_image_2: function(image) {
      var entry = this.get('current_page');
      if(entry) {
        Ember.set(entry, 'image2', image);
      }
    }
  }
});
