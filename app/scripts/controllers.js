'use strict';

angular.module('confusionApp')

        .controller('MenuController', ['$scope', 'menuFactory', function($scope, menuFactory) {
            
            $scope.tab = 1;
            $scope.filtText = '';
			$scope.showDetails = false;
            
            $scope.showMenu = false;
            $scope.message = "Loading ...";
                        menuFactory.getDishes().query(
                function(response) {
                    $scope.dishes = response;
                    $scope.showMenu = true;
                },
                function(response) {
                    $scope.message = "Error: "+response.status + " " + response.statusText;
                });

            $scope.select = function(setTab) {
                $scope.tab = setTab;
                
                if (setTab === 2) {
                    $scope.filtText = "appetizer";
                }
                else if (setTab === 3) {
                    $scope.filtText = "mains";
                }
                else if (setTab === 4) {
                    $scope.filtText = "dessert";
                }
                else {
                    $scope.filtText = "";
                }
            };

            $scope.isSelected = function (checkTab) {
                return ($scope.tab === checkTab);
            };
    
			$scope.toggleDetails = function() {
                $scope.showDetails = !$scope.showDetails;
			};
        }])
		
		.controller('ContactController', ['$scope', function($scope) {

            $scope.feedback = {mychannel:"", firstName:"", lastName:"", agree:false, email:"" };
            
            var channels = [{value:"tel", label:"Tel."}, {value:"Email",label:"Email"}];
            
            $scope.channels = channels;
            $scope.invalidChannelSelection = false;
                        
        }])

        .controller('FeedbackController', ['$scope', 'feedbackFactory', function($scope, feedbackFactory) {
            
            $scope.sendFeedback = function() {
                
                if ($scope.feedback.agree && ($scope.feedback.mychannel === "")) {
					$scope.invalidChannelSelection = true;
                    console.log('channel selection is not valid');
                }
                else {
                    
                    console.log($scope.feedback);
                    feedbackFactory.getFeedback().save($scope.feedback);
                    
                    $scope.invalidChannelSelection = false;
                    $scope.feedback = {mychannel:"", firstName:"", lastName:"", agree:false, email:"" };
                    $scope.feedback.mychannel="";
                    $scope.feedbackForm.$setPristine();
                    //console.log($scope.feedback);
                }
            };
        }])

        .controller('DishDetailController', ['$scope', '$stateParams', 'menuFactory', function($scope, $stateParams, menuFactory) {

            //var dish= menuFactory.getDish(parseInt($stateParams.id,10));
            $scope.dish = {};
            $scope.showDish = false;
            $scope.message="Loading ...";
                  $scope.dish = menuFactory.getDishes().get({id:parseInt($stateParams.id,10)})
            .$promise.then(
                            function(response){
                                $scope.dish = response;
                                $scope.showDish = true;
                            },
                            function(response) {
                                $scope.message = "Error: "+response.status + " " + response.statusText;
                            }
            );
            
            //$scope.dish = dish;
			
                    }])

        .controller('DishCommentController', ['$scope', 'menuFactory', function($scope,menuFactory) {
            
            $scope.dishCmnt = {rating:5, comment:"", author:"", date:""};
            $scope.ratings = [1,2,3,4,5];
            
            $scope.submitComment = function () {
                                $scope.dishCmnt.date = new Date().toISOString();
                console.log($scope.dishCmnt);
                                $scope.dish.comments.push($scope.dishCmnt);

                menuFactory.getDishes().update({id:$scope.dish.id},$scope.dish);
                                $scope.commentForm.$setPristine();
                                $scope.dishCmnt = {rating:5, comment:"", author:"", date:""};
            };
        }])
                
        // implement the IndexController and About Controller here
        .controller('IndexController', ['$scope','menuFactory','corporateFactory', function($scope, menuFactory, corporateFactory) {
            
            $scope.showDish = false;
            $scope.message="Loading featured dish...";
            $scope.featDish = menuFactory.getDishes().get({id:0})
                        .$promise.then(
                            function(response){
                                $scope.featDish = response;
                                $scope.showDish = true;
                            },
                            function(response) {
                                $scope.message = "Error: "+response.status + " " + response.statusText;
                            }
                        );
            
            //$scope.featDish = {'name':'Uthapizza'};
            //$scope.message = 'This is what you see when showDish is false';
            //console.log($scope.featDish.category);
            
            //$scope.featPromotion = menuFactory.getPromotion(0);
            $scope.showPromo = false;
            $scope.promoMessage="Loading promotion...";
            //$scope.featPromotion = menuFactory.getPromotion().get({id:0})
            $scope.featPromotion = menuFactory.getPromotion(0).get()
                        .$promise.then(
                            function(response){
                                $scope.featPromotion = response;
                                $scope.showPromo = true;
                            },
                            function(response) {
                                $scope.promoMessage = "Error: "+response.status + " " + response.statusText;
                            }
                        );
            //$scope.leader = corporateFactory.getLeader(3);
            $scope.showLeader = false;
            $scope.leaderMessage = "Loading leader...";
            $scope.leader = corporateFactory.getLeaders().get({id:3})
                        .$promise.then(
                            function(response){
                                $scope.leader = response;
                                $scope.showLeader = true;
                            },
                            function(response) {
                                $scope.leaderMessage = "Error: "+response.status + " " + response.statusText;
                            }
                        );
        }])

        .controller('AboutController', ['$scope','corporateFactory', function($scope, corporateFactory) {
            
            //$scope.leaders = corporateFactory.getLeaders();
            
            $scope.showLdrs = false;
            $scope.ldrsMessage = "Loading leadership...";
                        corporateFactory.getLeaders().query()
                    .$promise.then(
                        function(response) {
                            $scope.leaders = response;
                            $scope.showLdrs = true;
                        },
                        function(response) {
                            $scope.ldrsMessage = "Error: "+response.status + " " + response.statusText;
                        }
                    );
            
        }])
                
                
;
