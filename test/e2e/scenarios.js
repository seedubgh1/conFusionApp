'use strict';

describe('conFusion App E2E Testing', function() {
    it('should automatically redirect to / when location hash/fragment is empty', function() {

    browser.get('index.html');
    expect(browser.getLocationAbsUrl()).toMatch("/");

  });
  
  describe('index', function() {
    beforeEach(function() {
      browser.get('index.html#/');
    });

    it('should have a title', function() {
      expect(browser.getTitle()).
        toEqual('Ristorante Con Fusion');
    });
  });
    
  describe('menu 0 item', function() {
    beforeEach(function() {
      browser.get('index.html#/menu/0');
    });

    it('should have a name', function() {
          var name = element(by.binding('dish.name'));
          expect(name.getText()).
             toEqual('Uthapizza Hot $4.99');
    });

    it('should show the number of comments as', function() {
         expect(element.all(by.repeater('cmnts in dish.comments'))
            .count()).toEqual(8);

    });

    it('should show the first comment author as', function() {
          element(by.model('orderBy')).sendKeys('author');
            expect(element.all(by.repeater('cmnts in dish.comments'))
            .count()).toEqual(8);
          var author = element.all(by.repeater('cmnts in dish.comments'))
                      .first().element(by.binding('cmnts.author'));

          expect(author.getText()).toContain('25 Cent');
          
        // this is my own test
        // order comments by '-date' and check the text of
        // the first comment
        element(by.model('orderBy')).sendKeys('-date'); 
        var what_he_said = element.all(by.repeater('cmnts in dish.comments'))
                      .first().element(by.binding('cmnts.comment'));
        expect (what_he_said.getText()).toContain('Flabergasted!')

    });
});
    
});


/*

describe('menu 0 item', function() {
    beforeEach(function() {
      browser.get('index.html#/menu/0');
    });

    it('should have a name', function() {
          var name = element(by.binding('dish.name'));
          expect(name.getText()).
             toEqual('Uthapizza Hot $4.99');
    });

    it('should show the number of comments as', function() {
         expect(element.all(by.repeater('comment in dish.comments'))
            .count()).toEqual(5);

    });

    it('should show the first comment author as', function() {
          element(by.model('orderText')).sendKeys('author');
            expect(element.all(by.repeater('comment in dish.comments'))
            .count()).toEqual(5);
          var author = element.all(by.repeater('comment in dish.comments'))
                      .first().element(by.binding('comment.author'));

          expect(author.getText()).toContain('25 Cent');

    });
 }); */ 