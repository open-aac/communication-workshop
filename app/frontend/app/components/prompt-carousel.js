import Ember from 'ember';
import i18n from '../utils/i18n';

export default Ember.Component.extend({
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
  text_placeholder: function() {
    var type = this.get('type');
    if(type === 'usage_example') {
      return i18n.t('brief_definition_example', "Brief definition/example");
    } else if(type === 'modeling') {
      return i18n.t('brief_definition_example', "Brief explanation");
    } else if(type === 'prompt') {
      return i18n.t('prompt_text', "Prompt text");
    } else if(type === 'learning_project') {
      return i18n.t('project_name', "Project name");
    } else if(type === 'activity_idea') {
      return i18n.t('activity_name', "Activity name");
    } else if(type === 'book') {
      return i18n.t('book_title', "Book title");
    } else if(type === 'topic_starter') {
      return i18n.t('caption', "Caption");
    } else if(type == 'send_home') {
      return i18n.t('brief_definition_example', "Brief explanation");
    } else {
      return i18n.t('brief_definition_example', "Brief definition/example");
    }
  }.property('type'),
  url_placeholder: function() {
    var type = this.get('type');
    if(type === 'book') {
      return i18n.t('tarheel_amazon_url', "Tarheel/Amazon URL");
    } else if(type === 'video') {
      return i18n.t('youtube_url', "YouTube URL");
    } else {
      return i18n.t('related_url', "Related URL");
    }
  }.property('type'),
  prompt_type: function() {
    return this.get('type') === 'prompt';
  }.property('type'),
  promptOptions: function() {
    return [
      {name: i18n.t('correct_answer', "Fill in the Blank/Single Answer"), id: 'correct_answer'},
      {name: i18n.t('open_ended', "Open-Ended Question"), id: 'open_ended'}
    ];
  }.property(),
  description: function() {
    return this.get('type') === 'description_with_link' || this.get('type') == 'send_home';
  }.property('type'),
  include_url: function() {
    return this.get('type') === 'description_with_link' || this.get('type') === 'book' || this.get('type') == 'video';
  }.property('type'),
  include_sentence: function() {
    return this.get('type') === 'modeling';
  }.property('type'),
  related_words: function() {
    return this.get('type') === 'topic_starter';
  }.property('type'),
  check_for_images: function() {
    var entry = this.get('current_entry');
    if(this.get('type') === 'book' && entry && entry.url && (!entry.image || !entry.text)) {
      this.find_book(entry.url).then(function(res) {
        Ember.set(entry, 'book_type', res.book_type);
        Ember.set(entry, 'supplement', res.contents);
        if(!entry.text) {
          Ember.set(entry, 'text', res.title);
        }
        if(!entry.image) {
          Ember.set(entry, 'image', {
            image_url: res.image_url,
            thumbnail_url: res.image_url,
            license: 'private',
            author: 'see attribution',
            author_url: res.attribution,
            source_url: res.url
          });
        }
      }, function() { });
    } else if(this.get('type') === 'video') {
      var regex = (/(?:https?:\/\/)?(?:www\.)?youtu(?:be\.com\/watch\?(?:.*?&(?:amp;)?)?v=|\.be\/)([\w \-]+)(?:&(?:amp;)?[\w\?=]*)?/);
      var match = entry.url && entry.url.match(regex);
      if(match && match[1]) {
        // TODO: API lookup for video title
        var thumbnail = "https://img.youtube.com/vi/" + match[1] + "/hqdefault.jpg";
        if(!entry.image) {
          Ember.set(entry, 'image', {
            image_url: thumbnail,
            thumbnail_url: thumbnail,
            license: 'private',
            author: 'see attribution',
            author_url: entry.url,
            source_url: entry.url
          });
        }
      }
    }
  }.observes('type', 'current_entry.url'),
  find_book: function(url) {
    return Ember.$.ajax('/api/v1/search/books?url=' + encodeURIComponent(url), { type: 'GET' });
  },
  actions: {
    add: function() {
      this.get('entries').pushObject({});
      this.set('current_index', this.get('entries').length - 1);
    },
    next: function() {
      var idx = this.get('current_index') || 0;
      this.set('current_index', Math.min(idx + 1, (this.get('entries') || []).length - 1));
    },
    previous: function() {
      var idx = this.get('current_index') || 0;
      this.set('current_index', Math.max(idx - 1, 0));
    },
    update_current_image: function(image) {
      var entry = this.get('current_entry');
      if(entry) {
        Ember.set(entry, 'image', image);
      }
    },
    delete_current: function() {
      var entries = (this.get('entries') || []);
      var current_index = this.get('current_index') || 0;
      var res = [];
      entries.forEach(function(e, idx) {
        if(idx !== current_index) {
          res.push(e);
        }
      });
      this.set('entries', res);
      if(current_index > res.length - 1) {
        this.set('current_index', res.length - 1);
      }
    }
  }
});
