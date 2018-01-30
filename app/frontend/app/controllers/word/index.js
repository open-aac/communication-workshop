import Ember from 'ember';
import modal from '../../utils/modal';
import i18n from '../../utils/i18n';
import session from '../../utils/session';


export default Ember.Controller.extend({
  keyed_colors: function() {
    return [
      {"border":"#ccc","fill":"#fff","color":"White","types":["conjunction"],"style":Ember.String.htmlSafe("border-color: #ccc; background: #fff;")},
      {"border":"#dd0","fill":"#ffa","color":"Yellow","hint":"people","types":["pronoun"],"style":Ember.String.htmlSafe("border-color: #dd0; background: #ffa;")},
      {"border":"#6d0","fill":"#cfa","color":"Green","hint":"actions","types":["verb"],"style":Ember.String.htmlSafe("border-color: #6d0; background: #cfa;")},
      {"fill":"#fca","color":"Orange","hint":"nouns","types":["noun","nominative"],"border":"#ff7011","style":Ember.String.htmlSafe("border-color: #ff7011; background: #fca;")},
      {"fill":"#acf","color":"Blue","hint":"describing words","types":["adjective"],"border":"#1170ff","style":Ember.String.htmlSafe("border-color: #1170ff; background: #acf;")},
      {"fill":"#caf","color":"Purple","hint":"questions","types":["question"],"border":"#7011ff","style":Ember.String.htmlSafe("border-color: #7011ff; background: #caf;")},
      {"fill":"#faa","color":"Red","hint":"negations","types":["negation","expletive","interjection"],"border":"#ff1111","style":Ember.String.htmlSafe("border-color: #ff1111; background: #faa;")},
      {"fill":"#fac","color":"Pink","hint":"social words","types":["preposition"],"border":"#ff1170","style":Ember.String.htmlSafe("border-color: #ff1170; background: #fac;")},
      {"fill":"#ca8","color":"Brown","hint":"adverbs","types":["adverb"],"border":"#835d38","style":Ember.String.htmlSafe("border-color: #835d38; background: #ca8;")},
      {"fill":"#ccc","color":"Gray","hint":"determiners","types":["article","determiner"],"border":"#808080","style":Ember.String.htmlSafe("border-color: #808080; background: #ccc;")}
    ];
  }.property(),
  buttons: function() {
    var map = session.get('user.full_word_map') || [];
    var locale = this.get('model.locale');
    var word = this.get('model.word');
    var fallback = {
      background_color: this.get('model.background_color'),
      border_color: this.get('model.border_color'),
      label: this.get('model.word'),
      image_url: this.get('model.image.image_url'),
      id: this.get('model.id')
    };
    if(map[locale] && map[locale][word] && map[locale][word]['results'] && map[locale][word]['results'].length > 0) {
      return map[locale][word]['results'].map(function(r) {
        return {
          background_color: r.background_color || fallback.background_color,
          border_color: r.border_color || fallback.border_color,
          label: fallback.label,
          id: fallback.id,
          image_url: (r.image && r.image.image_url) || fallback.image_url
        };
      });
    }
    return [fallback];
  }.property('session.user.full_word_map', 'model.id'),
  single_button: function() {
    return this.get('buttons').length == 1 ? this.get('buttons')[0] : null;
  }.property('buttons.@each.image_url'),
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
    var desc = i18n.t('one_button', "1-word communicators");
    if(num === 2) {
      desc = i18n.t('two_button', "2-3 word communicators");
    } else if(num === 3) {
      desc = i18n.t('three_plus_button', "4+ word communicators");
    }
    var level = {
      modeling_examples: this.get('model.level_' + num + '_modeling_examples'),
      level: num,
      description: desc
    };
    level['level_' + num] = true;
    return level;
  }.property('modeling_level', 'model.id'),
  available_suggestions: function() {
    var map = session.get('user.full_word_map');
    var _this = this;
    var res = [];
    if(map[_this.get('model.locale')]) {
      var words = map[_this.get('model.locale')];
      (_this.get('model.related_suggestions') || []).forEach(function(word) {
        if(words[word]) {
          res.push(word);
        }
      });
      (_this.get('model.partner_suggestions') || []).forEach(function(word) {
        if(words[word]) {
          res.push(word);
        }
      });
    }
    return res.uniq();
  }.property('model.related_suggestions', 'session.user.full_word_map'),
  available_partners: function() {
    var map = session.get('user.full_word_map');
    var _this = this;
    var res = [];
    if(map[_this.get('model.locale')]) {
      var words = map[_this.get('model.locale')];
      (_this.get('model.partner_suggestions') || []).forEach(function(word) {
        if(words[word]) {
          res.push(word);
        }
      });
    }
    return res;
  }.property('model.partner_suggestions', 'session.user.full_word_map'),
  default_values: function() {
    if(this.get('editing') && this.get('model.defaults_loaded') != null) {
      var _this = this;
      _this.set('model.defaults_loaded', true);
      session.ajax('/api/v1/words/' + this.get('model.word') + '/defaults', {type: 'GET'}).then(function(res) {
        if(!_this.get('model.background_color')) {
          _this.set('model.background_color', res.background_color);
        }
        if(!_this.get('model.border_color')) {
          _this.set('model.border_color', res.border_color);
        }
        if(!_this.get('model.parts_of_speech')) {
          _this.set('model.parts_of_speech', res.parts_of_speech);
        }
        _this.set('model.sentence_suggestions', res.sentences);
        _this.set('model.partner_suggestions', res.pairs);
        _this.set('model.related_suggestions', res.related);

        if(!_this.get('model.image') && res.image_url) {
          session.ajax('https://www.opensymbols.org/api/v1/symbols/search?q=' + encodeURIComponent(_this.get('model.word')), { type: 'GET' }).then(function(list) {
            var item = list.find(function(i) { return i.image_url == res.image_url; });
            if(item) {
              _this.set('model.image', {
                image_url: item.image_url,
                thumbnail_url: item.image_url,
                license: item.license,
                author: item.author,
                author_url: item.author_url,
                license_url: item.license_url,
                source_url: item.source_url
              });
            }
          }, function(err) { debugger; });
        }
      }, function(err) {
        _this.set('model.defaults_loaded', false);
      });
    }
  }.observes('model.defaults_loaded', 'editing', 'model.background_color', 'model.border_color'),
  current_activity: function() {
    var activity = this.get('activity') || 'individual';
    var list = this.get('model.' + activity);
    var _this = this;
    if(activity == 'individual') {
      list = [];
      ['learning_projects', 'activity_ideas', 'books', 'topic_starters', 'send_homes', 'prompts', 'videos'].forEach(function(key) {
        var type = _this.get('model.' + key) || [];
        type.forEach(function(entry) {
          entry.type = key;
        });
        list = list.concat(type);
      });
    }

    var res = {
      type: activity,
      list: list
    };
    res[activity] = true;
    return res;
  }.property('activity', 'model.id'),
  word_status: function() {
    var res = {};
    if(this.get('adding.pending')) {
      res = {pending: true};
    } else if(this.get('adding.error')) {
      res = {error: true};
    }
    if(this.get('session.user')) {
      var words = this.get('session.user.current_words') || [];
      var model = this.get('model');
      var match = words.find(function(w) { return w.id == model.get('id'); });
      if(match) {
        res.added = true;
        res.concludes = match.concludes;
        res.users = match.users;
      }
    }
    return res;
  }.property('adding', 'session.user.id', 'session.user.current_words'),
  actions: {
    update_image: function(image, key) {
      if(!key || key === 'image') {
        this.set('model.image', image);
      }
    },
    add_word: function() {
      var _this = this;
      if(session.get('user')) {
        _this.set('adding', {pending: true});
        session.ajax('/api/v1/words/' + this.get('model.id') + '/add', {
          type: 'POST',
          data: {
            append: true
          }
        }).then(function(res) {
          _this.set('adding', null);
          session.get('user').reload();
        }, function(err) {
          _this.set('adding', {error: true});
        });
      }
    },
    remove_word: function() {
      var _this = this;
      if(session.get('user')) {
        _this.set('adding', {pending: true});
        session.ajax('/api/v1/words/' + this.get('model.id') + '/remove', {
          type: 'POST',
          data: {
            append: true
          }
        }).then(function(res) {
          _this.set('adding', null);
          session.get('user').reload();
        }, function(err) {
          _this.set('adding', {error: true});
        });
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
    color: function(color) {
      this.set('model.background_color', color.fill);
      this.set('model.border_color', color.border);
      if(!this.get('model.parts_of_speech') && color.types) {
        this.set('model.parts_of_speech', color.types[0]);
      }
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
    pin: function(activity_id, action) {
      var _this = this;
      session.ajax('/api/v1/words/' + this.get('model.id') + '/' + action + '/' + activity_id, {type: 'POST'}).then(function(res) {
        _this.get('session.user').reload();
      }, function(err) { debugger; });
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
    not_implemented: function() {
      alert('Coming Soon!');
    },
    suggestions: function() {
      var _this = this;
      modal.open('focus-suggestions', {type: 'activities', id: _this.get('model.id')});
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
