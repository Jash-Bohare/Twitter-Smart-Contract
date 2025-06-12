// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Twitter {
    // Keeps track of the total number of tweets
    uint256 public tweetCount;

    // Keeps track of the total number of messages
    uint256 public messageCount;

    // Struct to define the Tweet structure
    struct Tweet {
        uint256 id;
        address author;
        string content;
        uint256 createdAt;
    }

    // Struct to define the Message structure
    struct Message {
        uint256 id;
        address sender;
        address receiver;
        string content;
        uint256 createdAt;
    }

    // Stores all tweets globally using tweet ID
    mapping(uint256 => Tweet) public tweets;

    // Stores array of tweet IDs for each user (to track their personal tweets)
    mapping(address => uint256[]) public tweetsOf;

    // Stores direct messages between two users
    mapping(address => mapping(address => Message[])) public conversations;

    // Operator management: who is allowed to act on behalf of a user
    mapping(address => mapping(address => bool)) public operators;

    // Stores which accounts a user is following
    mapping(address => address[]) public following;

    // Internal function to create a tweet
    function _tweet(address _from, string memory _content) internal {
        tweetCount++;

        // Create a new Tweet struct and store it
        tweets[tweetCount] = Tweet({
            id: tweetCount,
            author: _from,
            content: _content,
            createdAt: block.timestamp
        });

        // Keep track of which user posted which tweet
        tweetsOf[_from].push(tweetCount);
    }

    // Internal function to send a direct message
    function _sendMessage(
        address _from,
        address _to,
        string memory _content
    ) internal {
        messageCount++;

        // Create the new message
        Message memory newMessage = Message({
            id: messageCount,
            sender: _from,
            receiver: _to,
            content: _content,
            createdAt: block.timestamp
        });

        // Save the message in both directions (like a chat)
        conversations[_from][_to].push(newMessage);
    }

    // Public function to post a tweet for the sender
    function tweet(string memory _content) external {
        _tweet(msg.sender, _content);
    }

    // Public function for an operator to post a tweet on behalf of someone else
    function tweet(address _from, string memory _content) external {
        require(operators[_from][msg.sender], "Not authorized operator.");
        _tweet(_from, _content);
    }

    // Public function to send a direct message from the sender
    function sendMessage(string memory _content, address _to) external {
        _sendMessage(msg.sender, _to, _content);
    }

    // Public function for an operator to send a message on behalf of someone else
    function sendMessage(
        address _from,
        address _to,
        string memory _content
    ) external {
        require(operators[_from][msg.sender], "Not authorized operator.");
        _sendMessage(_from, _to, _content);
    }

    // Public function to follow another user
    function follow(address _followed) external {
        require(_followed != msg.sender, "You cannot follow yourself.");
        following[msg.sender].push(_followed);
    }

    // Authorize an operator to act on your behalf
    function allow(address _operator) external {
        require(_operator != msg.sender, "You cannot be your own operator.");
        operators[msg.sender][_operator] = true;
    }

    // Revoke operator permission
    function disallow(address _operator) external {
        operators[msg.sender][_operator] = false;
    }

    // Get the latest N tweets from all users (most recent first)
    function getLatestTweets(uint256 count)
        external
        view
        returns (Tweet[] memory)
    {
        require(count > 0, "Count must be greater than zero.");

        // Limit result to available tweets if count exceeds total tweets
        uint256 resultCount = count > tweetCount ? tweetCount : count;
        Tweet[] memory result = new Tweet[](resultCount);

        // Start from the most recent tweet
        uint256 currentIndex = tweetCount;
        for (uint256 i = 0; i < resultCount; i++) {
            result[i] = tweets[currentIndex];
            currentIndex--;
        }

        return result;
    }

    // Get the latest N tweets from a specific user
    function getLatestTweetsOf(address user, uint256 count)
        external
        view
        returns (Tweet[] memory)
    {
        uint256[] storage userTweetIds = tweetsOf[user];
        uint256 userTweetCount = userTweetIds.length;

        require(userTweetCount > 0, "User has no tweets.");
        require(count > 0, "Count must be greater than zero.");

        // Limit result to available tweets if count exceeds user's tweets
        uint256 resultCount = count > userTweetCount ? userTweetCount : count;
        Tweet[] memory result = new Tweet[](resultCount);

        // Start from the user's most recent tweet
        uint256 currentIndex = userTweetCount - 1;
        for (uint256 i = 0; i < resultCount; i++) {
            uint256 tweetId = userTweetIds[currentIndex];
            result[i] = tweets[tweetId];

            // Prevent underflow when reaching the first element
            if (currentIndex == 0) {
                break;
            } else {
                currentIndex--;
            }
        }

        return result;
    }
}
