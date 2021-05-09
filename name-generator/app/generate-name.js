
const getRandomInArray = (arr) => {
    const selectedIndex = Math.floor(Math.random() * arr.length);
    return arr[selectedIndex];
};

const generateName = () => {
  const nameArray = ["John", "Susan", "Tony", "Nicole"];

  return {
      name: getRandomInArray(nameArray)
  };
};

exports.generateName = generateName;