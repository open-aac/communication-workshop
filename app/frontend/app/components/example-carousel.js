import Ember from 'ember';
import i18n from '../utils/i18n';
import session from '../utils/session';

export default Ember.Component.extend({
  didInsertElement: function() {
    var _this = this;
    var handler = function() {
      var e = _this.get('element');
      var fs = document.fullscreenElement || document.webkitFullscreenElement || document.mozFullScreenElement || document.msFullscreenElement
      _this.set('fullscreen', e == fs);
    };
    this.set('handler', handler);
    this.set('session', session);
    document.addEventListener('fullscreenchange', handler);
    document.addEventListener('webkitfullscreenchange', handler);
    document.addEventListener('onmozfullscreenchange', handler);
    document.MSFullscreenChange = handler;
  },
  willDestroyElement: function() {
    var handler = this.get('handler');
    document.removeEventListener('fullscreenchange', handler);
    document.removeEventListener('webkitfullscreenchange', handler);
    document.removeEventListener('onmozfullscreenchange', handler);
  },
  pinned: function() {
    var ids = this.get('session.user.starred_activity_ids');
    return !!(ids && this.get('current_entry.id') && ids.indexOf(this.get('current_entry.id')) != -1);
  }.property('session.user.starred_activity_ids', 'current_entry.id'),
  session: function() {
    return session;
  }.property(),
  tall: function() {
    return !this.get('fullscreen') && !this.get('update_revision_object');
  }.property('update_revision_object', 'fullscreen'),
  clear_on_change: function() {
    this.set('current_index', 0);
  }.property('entries', 'type'),
  current_entry: function() {
    var index = this.get('current_index') || 0;
    return (this.get('entries') || [])[index];
  }.property('entries', 'entries.length', 'current_index'),
  readable_index: function() {
    return (this.get('current_index') || 0) + 1;
  }.property('current_index'),
  prompt_type: function() {
    return this.get('type') === 'prompts' || this.get('current_entry.type') == 'prompts';
  }.property('type', 'current_entry.type'),
  description: function() {
    return this.get('type') === 'learning_projects' || this.get('type') == 'activity_ideas' ||
            this.get('current_entry.type') == 'learning_projects' || this.get('current_entry.type') == 'activity_ideas';
  }.property('type', 'current_entry.type'),
  include_url: function() {
    return this.get('type') === 'learning_projects' || this.get('type') == 'activity_ideas' || this.get('type') === 'books' || this.get('type') == 'videos' ||
            this.get('current_entry.type') === 'learning_projects' || this.get('current_entry.type') == 'activity_ideas' || this.get('current_entry.type') === 'books' || this.get('current_entry.type') == 'videos';
  }.property('type', 'current_entry.type'),
  include_sentence: function() {
    return this.get('type') === 'modeling' || this.get('current_entry.type') == 'modeling';
  }.property('type', 'current_entry.type'),
  related_words: function() {
    return this.get('type') === 'topic_starters' || this.get('current_entry.type') == 'topic_starters';
  }.property('type', 'current_entry.type'),
  actions: {
    next: function() {
      var idx = this.get('current_index') || 0;
      this.set('current_index', Math.min(idx + 1, (this.get('entries') || []).length - 1));
    },
    previous: function() {
      var idx = this.get('current_index') || 0;
      this.set('current_index', Math.max(idx - 1, 0));
    },
    confirm_revision: function() {
      this.sendAction('update_revision_object', this.get('current_entry'), this.get('revision_attribute'));
    },
    pin: function(action, activity) {
      if(activity.id) {
        this.sendAction('pin', activity.id, action);
      }
    },
    full_screen: function() {
      var e = this.get('element') || {};
      if(this.get('fullscreen')) {
        if(document.exitFullscreen) {
          document.exitFullscreen();
        } else if(document.webkitExitFullscreen) {
          document.webkitExitFullscreen();
        } else if(document.mozCancelFullScreen) {
          document.mozCancelFullScreen();
        } else if(document.msExitFullscreen) {
          document.msExitFullscreen();
        }
        this.set('fullscreen', false);
      } else {
        var fs = e.requestFullscreen || e.webkitRequestFullscreen || e.mozRequestFullScreen || e.msRequestFullscreen;
        if(e) {
          if(e.requestFullscreen) {
            e.requestFullscreen();
          } else if(e.webkitRequestFullscreen) {
            e.webkitRequestFullscreen();
          } else if(e.mozRequestFullScreen) {
            e.mozRequestFullScreen();
          } else if(e.msRequestFullscreen) {
            e.msRequestFullscreen();
          }
          this.set('fullscreen', true);
        }
      }
    }
  }
});
