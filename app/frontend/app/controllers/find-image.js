import Ember from 'ember';
import modal from '../utils/modal';
import i18n from '../utils/i18n';

export default modal.ModalController.extend({
  opening: function() {
    this.set('term', this.get('model.label'));
    this.set('images', null);
    if(!this.get('model.image') && this.get('term')) {
      this.send('search');
    }
  },
  closing: function() {
  },
  find_options: function() {
    var res = [
      {name: i18n.t('open_symbols', "OpenSymbols.org"), id: "open_symbols"},
      {name: i18n.t('flickr_cc', "Flickr Creative Commons"), id: "flickr"},
      {name: i18n.t('pixabay_photos', "Pixabay Photos"), id: "pixabay_photos"},
    ];
    return res;
  }.property(),
  open_symbols_search: function(text) {
    return Ember.$.ajax('https://www.opensymbols.org/api/v1/symbols/search?q=' + encodeURIComponent(text), { type: 'GET'
    }).then(function(data) {
      var res = [];
      data.forEach(function(item) {
        res.push({
            image_url: item.image_url,
            thumbnail_url: item.image_url,
            license: item.license,
            author: item.author,
            author_url: item.author_url,
            license_url: item.license_url,
            source_url: item.source_url

        });
      });
      return res;
    }, function(xhr, message) {
      var error = i18n.t('not_available', "Image retrieval failed unexpectedly.");
      if(message && message.error === "not online") {
        error = i18n.t('not_online_image_search', "Cannot search, please connect to the Internet first.");
      }
      return Ember.RSVP.reject(error);
    });
  },
  flickr_search: function(text) {
    if(!window.flickr_key) {
      return Ember.RSVP.reject(i18n.t('flickr_not_configured', "Flickr hasn't been properly configured for CoughDrop"));
    }
    // https://api.flickr.com/services/rest/?method=flickr.photos.search&api_key=5b397c920edee06dafeb630957e0a99e&text=cat&safe_search=2&media=photos&extras=license%2C+owner_name&format=json&nojsoncallback=1
    return Ember.$.ajax('https://api.flickr.com/services/rest/?method=flickr.photos.search&api_key=' + window.flickr_key + '&text=' + text + '&safe_search=2&media=photos&license=2%2C3%2C4%2C5%2C6%2C7&extras=license%2C+owner_name&format=json&nojsoncallback=1', { type: 'GET'
    }).then(function(data) {
      var res = [];

      var licenses = {
        '1': {name: 'CC By_NC-SA', url: 'http://creativecommons.org/licenses/by-nc-sa/2.0/'},
        '2': {name: 'CC By_NC', url: 'http://creativecommons.org/licenses/by-nc/2.0/'},
        '3': {name: 'CC By_NC-ND', url: 'http://creativecommons.org/licenses/by-nc-nd/2.0/'},
        '4': {name: 'CC By', url: 'http://creativecommons.org/licenses/by/2.0/'},
        '5': {name: 'CC By-SA', url: 'http://creativecommons.org/licenses/by-sa/2.0/'},
        '6': {name: 'CC By-ND', url: 'http://creativecommons.org/licenses/by-nd/2.0/'},
        '7': {name: 'public domain', url: 'https://www.flickr.com/commons/usage/'}
      };

      (((data || {}).photos || {}).photo || []).forEach(function(photo) {
        var license = licenses[photo.license];
        if(license) {
          res.push({
            image_url: "https://farm" + photo.farm + ".staticflickr.com/" + photo.server + "/" + photo.id + "_" + photo.secret + "_b.jpg",
            thumbnail_url: "https://farm" + photo.farm + ".staticflickr.com/" + photo.server + "/" + photo.id + "_" + photo.secret + "_n.jpg",
            license: license.name,
            author: photo.ownername,
            author_url: "https://www.flickr.com/people/" + photo.owner + "/",
            license_url: license.url,
            source_url: "https://www.flickr.com/photos/" + photo.id + "/"
          });
        }
      });
      return res.slice(0, 20);
    }, function(xhr, message) {
      return i18n.t('not_available', "Image retrieval failed unexpectedly.");
    });
  },
  pixabay_search: function(text, filter) {
    if(!window.pixabay_key) {
      return Ember.RSVP.reject(i18n.t('pixabay_not_configured', "Pixabay hasn't been properly configured for CoughDrop"));
    }
    var type = 'photo';
    return Ember.$.ajax('https://pixabay.com/api/?key=' + window.pixabay_key + '&q=' + text + '&image_type=' + type + '&per_page=30&safesearch=true', { type: 'GET'
    }).then(function(data) {
      var res = [];
      ((data || {}).hits || []).forEach(function(hit) {
        var content_type = 'image/jpeg';
        var ext = 'jpg';
        if(hit.webformatURL && hit.webformatURL.match(/png$/)) {
          content_type = 'image/png';
          ext = 'png';
        }
        res.push({
          image_url: hit.webformatURL,
          thumbnail_url: hit.previewURL || hit.webformatURL,
          width: hit.webformatWidth,
          height: hit.webformatHeight,
          license: 'public domain',
          author: 'unknown',
          author_url: 'https://creativecommons.org/publicdomain/zero/1.0/',
          license_url: 'https://creativecommons.org/publicdomain/zero/1.0/',
          source_url: hit.pageURL
        });
      });
      console.log(res);
      return res;
    }, function(xhr, message) {
      return i18n.t('not_available', "Image retrieval failed unexpectedly.");
    });
  },
  actions: {
    search: function() {
      var _this = this;
      _this.set('images', {loading: true});
      var library = _this.get('image_library');
      var term = _this.get('term');
      if(term.match(/^http/)) {
        var url = term;
        // TODO: handle this server-side
//         if(!term.match(/^https/)) {
//           url = "https://images.weserv.nl/?url=" + url.replace(/^https?:\/\//, '');
//         }
        _this.set('model.image', {
          image_url: url,
          source_url: term,
          license: 'private'
        });
        return;
      }
      var search = _this.open_symbols_search;
      if(library == 'flickr') {
        search = _this.flickr_search;
      } else if(library == 'pixabay_photos') {
        search = function(str) { return _this.pixabay_search(str, 'photo'); };
      }
      search(term).then(function(res) {
        _this.set('images', res);
      }, function() {
        _this.set('images', {error: true});
      });
    },
    preview: function(image) {
      Ember.set(image, 'uneditable', true);
      this.set('model.image', image);
    },
    list: function() {
      this.set('model.image', null);
    },
    clear: function() {
      this.set('model.image', null);
      this.set('images', null);
    },
    select: function() {
      modal.close({image: this.get('model.image')});
    }
  }
});
