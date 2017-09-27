require 'json_api/lesson'

class Api::LessonsController < ApplicationController
  def index
    lessons = Lesson.all
    if params['sort'] == 'recommended' && @api_user
      lessons = [] # TODO: show next recommended lesson first
    else
      lessons = lessons.where(:root => true).order('id')
    end
    render json: JsonApi::Lessons.paginate(params, lessons)
  end
  
  def show
    lesson = Lesson.find_or_initialize_by_path(params['id'])
    return unless exists?(lesson, params['id'])
    return unless allowed?(lesson, 'view')
    render json: JsonApi::Lesson.as_json(lesson, wrapper: true, permissions: @api_user)
  end
  
  def update
    lesson = Lesson.find_or_initialize_by_path(params['id'])
    return unless exists?(lesson, params['id'])
    return unless allowed?(lesson, 'revise')
    if lesson.process(params['lesson'], {'user' => @api_user})
      render json: JsonApi::Lesson.as_json(lesson, wrapper: true, permissions: @api_user)
    else
      api_error(400, {error: 'error saving lesson settings'})
    end
  end
  
  def destroy
    lesson = Lesson.find_by_path(params['id'])
    return unless exists?(lesson, params['id'])
    return unless allowed?(lesson 'delete')
    lesson.destroy
    render json: JsonApi::Lesson.as_json(lesson, wrapper: true, permissions: @api_user)
  end
end
