import Ember from 'ember';
import config from './config/environment';

const Router = Ember.Router.extend({
  location: config.locationType,
  rootURL: config.rootURL
});

Router.map(function() {
  this.route('index', {path: '/'});
  this.route('login', {path: '/login'});
  this.route('user', {path: '/users/:user_id'});
  this.route('categories', {path: '/categories/:locale'});
  this.route('words', {path: '/words/:locale'});
  this.route('category', {path: '/categories/:category/:locale'}, function() {
  });
  this.route('tallies', {path: '/scratch/tallies'});
  this.route('training', {path: '/scratch/training'});
  this.route('book', {path: '/books/:id'});
  this.route('word', {path: '/words/:word/:locale'}, function() {
    this.route('quiz', {path: 'quizzes/:quiz_id'});
    this.route('story', {path: 'stories/:story_id'});
    this.route('practice', {path: 'practice'});
    this.route('project', {path: 'projects/:project_id'}); // STEM projects
    this.route('picture', {path: 'pictures/:picture_id'}); // topic-starters
    this.route('role_play', {path: 'role_plays/:play_id'});
    this.route('stats', {path: 'stats'});
  });
});

export default Router;
