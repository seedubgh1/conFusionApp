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


function func(prop, val) {
  //var jsonStr = '{"'+prop+'":'+val+'}';
  var jsonStr = '{"'+prop+'":"'+val+'"}';
  return JSON.parse(jsonStr);
};


console.log(questions.results.length);

alexa_q = func("Santas reindeer are cared for by one of the Christmas elves, what is his name?",'17');

console.log('--=== alexa q ===--');
console.log(alexa_q);

console.log('--=== alex q Object.keys ===--');
console.log(Object.keys(alexa_q));
console.log('--=== alex q Object.keys wink wink ===--');
alexa_q_keys = Object.keys(alexa_q);
console.log(Object.keys(alexa_q_keys));

var answers = [];
answers = answers.concat(questions.results[0].correct_answer);
answers = answers.concat(questions.results[0].incorrect_answers);

console.log('--=== answers ===--');
console.log(answers);

//console.log('--=== looping through keys ===--');

for (i = 0; i < alexa_q_keys.length; i += 1) {
  //console.log(alexa_q_keys[i]);
  alexa_q[alexa_q_keys[i]] = answers;
};

//console.log('--=== are you hootie? ===--');
//console.log(typeof alexa_q);
//console.log(alexa_q["Santas reindeer are cared for by one of the Christmas elves, what is his name?"]);
//console.log(alexa_q[alexa_q_keys[0]]);

console.log('--=== final answer ===--');
console.log(alexa_q);
