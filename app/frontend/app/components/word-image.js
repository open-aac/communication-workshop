import Ember from 'ember';
import i18n from '../utils/i18n';
import session from '../utils/session';
import Component from '@ember/component';

export default Component.extend({
  didInsertElement: function() {
    var _this = this;
    var handler = function() {
      var e = _this.get('element');
      var fs = document.fullscreenElement || document.webkitFullscreenElement || document.mozFullScreenElement || document.msFullscreenElement;
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
  actions: {
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
