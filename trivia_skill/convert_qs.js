
questions = {
	"response_code": 0,
	"results": [{
		"category": "Entertainment: Music",
		"type": "multiple",
		"difficulty": "easy",
		"question": "Which country does the band Rammstein hail from?",
		"correct_answer": "Germany",
		"incorrect_answers": ["Austria",
		"Armenia",
		"Belgium"]
	},
	{
		"category": "Art",
		"type": "multiple",
		"difficulty": "medium",
		"question": "Which artist&rsquo;s studio was known as &#039;The Factory&#039;?",
		"correct_answer": "Andy Warhol",
		"incorrect_answers": ["Roy Lichtenstein",
		"David Hockney",
		"Peter Blake"]
	},
	{
		"category": "Sports",
		"type": "multiple",
		"difficulty": "medium",
		"question": "A stimpmeter measures the speed of a ball over what surface?",
		"correct_answer": "Golf Putting Green",
		"incorrect_answers": [" Football Pitch",
		"Cricket Outfield",
		"Pinball Table"]
	},
	{
		"category": "History",
		"type": "multiple",
		"difficulty": "medium",
		"question": "When did the United States formally declare war on Japan, entering World War II?",
		"correct_answer": "December 8, 1941",
		"incorrect_answers": ["June 6, 1944",
		"June 22, 1941",
		"September 1, 1939"]
	},
	{
		"category": "Entertainment: Television",
		"type": "multiple",
		"difficulty": "easy",
		"question": "In Star Trek: The Next Generation, what is the name of Data&#039;s cat?",
		"correct_answer": "Spot",
		"incorrect_answers": ["Mittens",
		"Tom",
		"Kitty"]
	}]
};


var func = function (prop, val) {
  //var jsonStr = '{"'+prop+'":'+val+'}';
  var jsonStr = '{"'+prop+'":"'+val+'"}';
  return JSON.parse(jsonStr);
};

var convert_questions = function (questions) {
var questions = questions.results;
var q_set= [];
var alexa_q = {};

for (i = 0; i < questions.length; i += 1) {
  //console.log(questions[i].question);  
  alexa_q = func(questions[i].question,'17');

  //--- form answers ---
  answers = [];
  answers = answers.concat(questions[i].correct_answer);
  answers = answers.concat(questions[i].incorrect_answers);
  //console.log('---=== answers ===---');
  //console.log(answers);

  console.log(Object.keys(alexa_q)[0]);
  alexa_q[Object.keys(alexa_q)[0]] = answers;

  //console.log('---=== the question ===---');
  //console.log(alexa_q);

  q_set.push(alexa_q);
};
  return q_set;
};

var theSet = {};
theSet.QUESTIONS_EN_US = convert_questions(questions);
theSet.QUESTIONS_EN_GB = convert_questions(questions);
theSet.QUESTIONS_DE_DE = convert_questions(questions);
console.log('---=== the set==---');
console.log(theSet);
