import Ember from 'ember';
import modal from '../utils/modal';
import i18n from '../utils/i18n';
import session from '../utils/session';
import progress_tracker from '../utils/progress_tracker';

export default modal.ModalController.extend({
  opening: function() {
    var _this = this;
    _this.set('status', {loading: true});
    var key = Math.random();
    _this.set('status_key', key);

    session.ajax('/api/v1/words/packet', {
      type: 'POST',
      data: {
        word_ids: this.get('model.words').join('::')
      }
    }).then(function(res) {
      progress_tracker.track(res.progress, function(progress) {
        if(_this.get('status_key') == key) {
          if(progress.status == 'finished') {
            _this.set('status', {finished: true, download_url: progress.result});
          } else if(progress.status == 'errored') {
            _this.set('status', {errored: true});
          } else {
            _this.set('status', {loading: true, percent: (progress.percent || 0.0)});
          }
          console.log('status', status);
        }
      });
    }, function(err) {
      _this.set('status', {errored: true});
    });
  },
  num_percent: function() {
    return Math.round(100 * (this.get('status.percent') || 0));
  }.property('status.percent'),
  num_style: function() {
    return new Ember.String.htmlSafe("width: " + this.get('num_percent') + "%;");
  }.property('num_percent'),
  pct: function() {
    return Math.round(this.get('status.percent') || 0);
  }.property('status.percent'),
});
