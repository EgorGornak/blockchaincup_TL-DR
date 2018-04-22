pragma solidity ^0.4.16;

contract owned {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner  public {
        owner = newOwner;
    }
}

contract TokenWinx is owned {
    mapping (address => uint) public balances;
    function give(uint amount) public {
        balances[msg.sender] += amount;
    }
    function send(address receiver, uint amount) public {
        if(balances[msg.sender] < amount) return;
        balances[msg.sender] -= amount;
        balances[receiver] += amount;
    }
    function balanceOf(address addr) public constant returns (uint balance) {
        balance = balances[addr];
    }
}

contract tokenVote is owned {
    // Public variables of the token
    uint8 public currStep = 0;
    
    address public TokenWinx_address;
    
    uint8 public decimals = 18;
    // 18 decimals is the strongly suggested default, avoid changing it

    mapping (address => address) public voters; // map of registered voters in system
    mapping (address => Expert) public experts; // map of registered experts in system
    mapping (address => bool) public isExpert; // checking map that current account is registered as expert
    mapping (address => bool) public isVoter; // checking map that current account is registered as voter
    mapping (address => uint32) public expertsIndexes; // auxiliary map of indexes in expertsArray
    address[] public expertsArray; // array of expert addresses 
    mapping (address => uint32) public projects; // map of projects registered in system
    address[] public votersArray; // array of voter addresses
    mapping (address => uint32) public votersIndexes; // auxiliary map of indexes in votersArray
    mapping (address => bool) public isProject; //checking map that  current account is registered as project
    mapping (address => uint32) public projectsIndexes; // auxiliary map of indexes in projectsArray
    address[] public projectsArray; // addresses of registered Projects
    uint32[] public projectsVotes;  // number of votes for current project
    
    constructor(address _TokenWinx_address) public {
        TokenWinx_address = _TokenWinx_address;
    }
    
    struct Expert { // Experts that can vote for Projects
        uint32 votes;
        uint32 usedVotes;
    }
    
    function vote (address project, uint32 count) public {
        require(currStep == 2); // experts can vote for projects only on the second step
        require(isProject[project]); // check that project is registered
        require(isExpert[msg.sender]); // check that sender is expert
        require(experts[msg.sender].votes - experts[msg.sender].usedVotes >= count); // check that expert have enough unused votes
        experts[msg.sender].usedVotes += count; // add appropriate number of votes to project
        projects[project] += count;
        projectsVotes[projectsIndexes[project]] += count;
    }
    
    function setProjects(address[] newProjects) public { // Set projects array to current argument array of addresses
        require(currStep == 0); // Owner can set projects only when voting isn`t proccessing
        require(msg.sender == owner);
        uint32 i = 0;
        
        while (i < projectsArray.length) { // delete current projects arrays and maps
            isProject[projectsArray[i]] = false;
            projects[projectsArray[i]] = 0;
            i++;
        }
        while(projectsArray.length != 0) {
            delete projectsArray[projectsArray.length - 1];
            delete projectsVotes[projectsVotes.length - 1];
        }
        i = 0;
        while (i < newProjects.length) { // set project arrays and map to argument of function
            projectsArray.push(newProjects[i]);
            isProject[newProjects[i]] = true;
            projectsIndexes[newProjects[i]] = i;
            projectsVotes.push(0);
            i++;
        }
    }
    
    function giveVote (address expert) public { // set Voter pointer to expert
        require(currStep == 1); // voters can give their votes before second step of voting 
        TokenWinx _TokenWinx = TokenWinx(TokenWinx_address);
        if (_TokenWinx.balanceOf(msg.sender) == 0) { // check that sender is owner of Winx tokens
            if (isVoter[msg.sender]) { // if he`s isn`t owner of Winx tokens then delete him from voting system 
                deleteVoter(msg.sender);
                return;
            }
        }
        require(!isExpert[msg.sender]);
        if (!isVoter[msg.sender]) { // if voter isn`t registered then register him
            addVoter(msg.sender, expert);
        } else if (isExpert[voters[msg.sender]]) {
            experts[voters[msg.sender]].votes--;
        }
        require(isExpert[expert]); // check that address of receiver of vote is registered expert
        experts[expert].votes++;
    }
    
    function addExpert(address user) public { // owner can register new expert
        TokenWinx _TokenWinx = TokenWinx(TokenWinx_address);
        require(currStep == 0); // Requires that voting is stopeed to avoid problems
        require(msg.sender == owner); // Only administrator can add or delete experts
        require(_TokenWinx.balanceOf(user) > 0); // Can add only user with token Winx
        require(!isExpert[user]); // Requires that expert isn`t registered;
        if (isVoter[user]) {
            deleteVoter(user);
        }
        isExpert[user] = true;
        experts[user] = Expert(1,0);
        expertsArray.push(user);
        expertsIndexes[user] = uint32(expertsArray.length) - 1;
    }
    
    function deleteVoter(address tmp) private { // auxiliary function, that deletes voter from system
        isVoter[tmp] = false;
        if (isExpert[voters[tmp]]) {
            experts[voters[tmp]].votes--;
        }
        delete voters[tmp];
        uint32 i = votersIndexes[tmp];
        delete votersIndexes[tmp];
        votersArray[i] = votersArray[votersArray.length - 1];
        votersIndexes[votersArray[i]] = i;
        delete votersArray[votersArray.length - 1];
    }
    
    function addVoter(address user,address expert) private { // auxiliary functionn, that register new voter with pointer to expert
        isVoter[user] = true;
        voters[user] = expert;
        votersArray.push(user);
        votersIndexes[user] = uint32(votersArray.length) - 1;
    }
    
    function deleteExpert(address user) public {  // Owner can delete expert from system
        require(currStep == 0); // Requires that voting is stopeed to avoid problems
        require(msg.sender == owner); 
        require(isExpert[user]); // Allowed to delete only registered experts
        isExpert[user] = false;
        delete experts[user];
        uint32 i = expertsIndexes[user];
        delete expertsIndexes[user];
        expertsArray[i] = expertsArray[expertsArray.length - 1];
        expertsIndexes[expertsArray[i]] = i;
        delete expertsArray[expertsArray.length - 1];
    }
    
    function checkVoters() private { // check that voters are valid
        TokenWinx _TokenWinx = TokenWinx(TokenWinx_address);
        for (uint32 i = 0; i < votersArray.length; i++) {
            address tmp = votersArray[i];
            if (_TokenWinx.balanceOf(tmp) == 0) { // if balance of current voter is 0 then he isn`t valid
                deleteVoter(tmp);
            } 
        }
    }
    
    function clearProjects() private { // clear projects votes before the voting
        for (uint32 i = 0; i < projectsVotes.length; i++) {
            projectsVotes[i] = 0;
            projects[projectsArray[i]] = 0;
        }
    }
    
    function nextStep() public { // go to the next step of voting
        require (msg.sender == owner); // only owner can manipulate with voting steps
        require (currStep < 2); // check that current step isn`t terminal
        currStep++;
        if (currStep == 2) {
            checkVoters();
        } else if (currStep == 1) {
            clearProjects();
        }
    }
    
    function stopVoting() public { // owner stops voting
        require(msg.sender == owner);
        require(currStep == 2); // check that current step is terminal
        currStep = 0; // stop voting
        for (uint256 i = 0; i < expertsArray.length; i++) { // set nulls to all experts
            experts[expertsArray[i]].usedVotes = 0;
        }
    }
}
