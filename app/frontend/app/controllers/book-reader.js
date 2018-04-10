import Ember from 'ember';
import modal from '../utils/modal';
import i18n from '../utils/i18n';
import session from '../utils/session';

var controller = null;
export default modal.ModalController.extend({
  launch_url: function() {
    var res = "/books/launch";
    if(this.get('model.book.book_type') == 'communication_workshop') {
      res = res + "?id=" + this.get('model.book.id');
    } else  {
      res = res + "?url=" + this.get('model.book.url');
    }
    return res;
  }.property('model.book.id', 'model.book.url', 'model.book.book_type')
});
