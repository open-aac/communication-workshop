import Ember from 'ember';
import EmberObject from '@ember/object';
import { Promise } from 'rsvp';
import $ from 'jquery';
import { later } from '@ember/runloop'; 
import Controller from '@ember/controller';

var modal = EmberObject.extend({
  setup: function(route) {
    if(this.last_promise) { this.last_promise.reject('closing due to setup'); }
    this.route = route;
    this.settings_for = {};
    this.controller_for = {};
  },
  reset: function() {
    this.route = null;
  },
  open: function(template, options) {
    if(this.last_promise || this.last_template) {
      this.close();
    }
    if(!this.route) { throw "must call setup before trying to open a modal"; }

    this.settings_for[template] = options;
    this.last_template = template;
    this.route.render(template, { into: 'application', outlet: 'modal'});
    var _this = this;
    return new Promise(function(resolve, reject) {
      _this.last_promise = {
        resolve: resolve,
        reject: reject
      };
    });
  },
  is_open: function(template) {
    if(template) {
      return this.last_template == template;
    } else {
      return !!this.last_template;
    }
  },
  is_closeable: function() {
    return $(".modal").attr('data-uncloseable') != 'true';
  },
  close: function(success) {
    if(!this.route) { return; }
    if(this.last_promise) {
      if(success || success === undefined) {
        this.last_promise.resolve(success);
      } else {
        this.last_promise.reject('force close');
      }
      this.last_promise = null;
    }
    this.last_template = null;
    if(this.route.disconnectOutlet) {
      if(this.last_controller && this.last_controller.closing) {
        this.last_controller.closing();
      }
      this.route.disconnectOutlet({
        outlet: 'modal',
        parentView: 'application'
      });
    }
    if(this.queued_template) {
      later(function() {
        if(!modal.is_open()) {
          modal.open(modal.queued_template);
          modal.queued_template = null;
        }
      }, 2000);
    }
  },
}).create();

modal.ModalController = Controller.extend({
  actions: {
    opening: function() {
      var template = this.get('templateName') || this.get('renderedName') || this.constructor.toString().split(/:/)[1];
      var settings = modal.settings_for[template] || {};
      var controller = this;
      modal.last_controller = controller;
      controller.set('model', settings);
      if(controller.opening) {
        controller.opening();
      }
    },
    closing: function() {
      if(this.closing) {
        this.closing();
      }
    },
    close: function() {
      modal.close();
    }
  }
});

export default modal;
