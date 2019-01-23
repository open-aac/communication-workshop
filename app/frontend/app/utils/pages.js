import Ember from 'ember';
import session from './session';
import EmberObject from '@ember/object';
import { Promise } from 'rsvp';
import $ from 'jquery';

var pages = EmberObject.extend({
  all: function(type, initial_opts, partial_callback) {
    return new Promise(function(resolve, reject) {
      var all_results = [];
      var result_type = initial_opts.result_type;
      delete initial_opts['result_type'];
      var find_next = function(type, opts) {
        if(type.match(/\/api\//)) {

          session.ajax(type, opts).then(function(list) {
            if(result_type) {
              all_results = all_results.concat(list[result_type]);
            } else {
              all_results.push(list);
            }
            if(partial_callback) {
              partial_callback(all_results);
            }
            if(list.meta && list.meta.next_url) {
              find_next(list.meta.next_url, {result_type: result_type});
            } else {
              resolve(all_results);
            }
          }, function(err) {
            reject(err);
          });
        } else {
          var args = $.extend({}, opts);
          session.data_store.query(type, opts).then(function(list) {
            var meta = list.meta;
            all_results = all_results.concat(list.map(function(r) { return r; }));
            if(partial_callback) {
              partial_callback(all_results);
            }
            if(meta && meta.more) {
              args.per_page = meta.per_page;
              args.offset = meta.next_offset;
              find_next(type, args);
            } else {
              resolve(all_results);
            }
          }, function(err) {
            reject(err);
          });
        }
      };
      find_next(type, initial_opts);
    });
  }
}).create();

export default pages;
