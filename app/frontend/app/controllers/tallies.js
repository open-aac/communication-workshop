import Ember from 'ember';
import session from '../utils/session';

var results = [
  {
    title: "Favorite Color",
    key: 'color',
    labels: [
      {
        text: "Red",
        key: 'red',
        color: "#a00",
        border: "#800",
      },
      {
        text: "Orange",
        key: 'orange',
        color: "#f4a142",
        border: "#840",
      },
      {
        text: "Yellow",
        key: 'yellow',
        color: "#fff426",
        border: "#882",
      },
      {
        text: "Green",
        key: 'green',
        color: "#29ff26",
        border: "#181",
      },
      {
        text: "Blue",
        key: 'blue',
        color: "#2655ff",
        border: "#138",
      },
      {
        text: "Purple",
        key: 'purple',
        color: "#ba26ff",
        border: "#618",
      },
      {
        text: "Other",
        key: 'other',
        color: "#aaa",
        border: "#888",
      }
    ]
  },
  {
    title: "Where are You?",
    key: 'location',
    labels: [
      {
        text: "Northeast",
        key: 'northeast',
        color: "#a00",
        border: "#800",
      },
      {
        text: "Midwest",
        key: 'midwest',
        color: "#fff426",
        border: "#882",
      },
      {
        text: "South",
        key: 'south',
        color: "#29ff26",
        border: "#181",
      },
      {
        text: "West",
        key: 'west',
        color: "#2655ff",
        border: "#138",
      },
      {
        text: "Outside the U.S.",
        key: 'outside',
        color: "#ba26ff",
        border: "#618",
      }
    ]
  },
  {
    title: "Twilight Fans",
    key: 'twilight',
    labels: [
      {
        text: "Edward Cullen",
        key: 'edward',
        color: "#2655ff",
        border: "#138",
      },
      {
        text: "Jacob Black",
        key: 'red',
        color: "#a00",
        border: "#800",
      },
      {
        text: "Party Pooper",
        key: 'none',
        color: "#aaa",
        border: "#888",
      }
    ]
  }
];
export default Ember.Controller.extend({
  init: function() {
    var _this = this;
    session.ajax('/api/v1/search/tallies', {type: 'GET'}).then(function(data) {
      _this.set('data', data);
    });
    Ember.run.later(function() {
      _this.init();
    }, 5000);
  },
  current_results: function() {
    var idx = this.get('current_index') || 0;
    var res = results[idx];
    var data = this.get('data') || {};
    var max = 0;
    for(var idx in (data[res.key] || {})) {
      max = Math.max(max, data[res.key][idx]);
    }
    Ember.set(res, 'entries', []);
    res.labels.forEach(function(l) {
      var total = (data[res.key] || {})[l.key] || 0;
      var pct = Math.round(total / max * 100);
      if(isNaN(pct)) { pct = 0; }
      var style = Ember.String.htmlSafe("height: 30px; border: 1px solid " + l.border + "; background: " + l.color + "; width: " + pct + "%; border-radius: 5px; color: #fff; padding-left: 5px; padding-top: 3px; overflow: hidden;" + (pct <= 0 ? "visibility: hidden;" : ""));
      res.entries.push({
        text: l.text,
        total: total,
        style: style
      });
    });
    return res;
  }.property('data', 'current_index'),
  actions: {
    next: function() {
      var idx = this.get('current_index') || 0;
      idx = Math.min(idx + 1, results.length);
      this.set('current_index', idx);
    },
    previous: function() {
      var idx = this.get('current_index') || 0;
      idx = Math.max(idx - 1, 0);
      this.set('current_index', idx);
    }
  }
});
