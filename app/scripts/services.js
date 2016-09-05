'use strict';

angular.module('confusionApp')
        .constant("baseURL","http://localhost:3000/")

        .factory('feedbackFactory',['$resource', 'baseURL', function($resource,baseURL) {
            var fb_fac = {};
            
            fb_fac.getFeedback = function() {
                //return feedback resource;
                return $resource(baseURL+"feedback/:id",null);
            };
    
            return fb_fac;
        }])

        .service('menuFactory', ['$resource', 'baseURL', function($resource,baseURL) {
    
			this.getDishes = function(){
                  return $resource(baseURL+"dishes/:id",null,  {'update':{method:'PUT' }});
                                    };

            this.getPromotion = function(index) {
                //return $resource(baseURL+"promotions/:id",null);
                return $resource(baseURL+"promotions/" + index)
    
            };
        }])

        .factory('corporateFactory', ['$resource', 'baseURL', function($resource,baseURL) {
    
            var corpfac = {};
    
            corpfac.getLeaders = function() {
                //return leadership resource;
                return $resource(baseURL+"leadership/:id",null,  {'update':{method:'PUT' }});
            };
    
            return corpfac;
    
        }])

;
