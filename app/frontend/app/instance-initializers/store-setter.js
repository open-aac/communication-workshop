import session from '../utils/session';

export default {
  name: 'store-setter',
  initialize: function(instance) {
    session.data_store = instance.lookup('service:store');
  }
};
