import Ember from 'ember';
import modal from '../utils/modal';
import i18n from '../utils/i18n';
import session from '../utils/session';

var youtube_regex = (/(?:https?:\/\/)?(?:www\.)?youtu(?:be\.com\/watch\?(?:.*?&(?:amp;)?)?v=|\.be\/)([\w \-]+)(?:&(?:amp;)?[\w\?=]*)?/);
export default modal.ModalController.extend({
  launch_url: function() {
    var url = this.get('model.video.url');
    var youtube_match = url && url.match(youtube_regex);
    var youtube_id = youtube_match && youtube_match[1];
    if(youtube_id) {
      url = "https://www.youtube.com/embed/" + youtube_id + "?rel=0&autoplay=1&controls=1"
    }
    return url;
  }.property('model.video.id', 'model.video.url')
});
