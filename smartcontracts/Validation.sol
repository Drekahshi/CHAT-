// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
// Note: This contract depends on CHATToken and ERC8004ReputationRegistry, so in Remix, deploy those first and pass their addresses to the constructor.

/**
 * @title ERC8004ValidationRegistry
 * @dev Manages task validation and agent settlements
 */
contract ERC8004ValidationRegistry is Ownable {
    using SafeMath for uint256;
    struct TaskRequest {
        uint256 taskId;
        uint256 serverAgentTokenId;
        uint256 validatorAgentTokenId;
        string taskDescription;
        bytes32 dataHash;
        uint256 deadline;
        uint256 requiredValidations;
        uint256 rewardAmount;
        uint256 createdAt;
        bool isComplete;
    }
    struct TaskExecution {
        uint256 taskId;
        uint256 executionTime;
        bytes32 resultHash;
        string resultSummary;
        uint256 confidenceScore;
        uint256 timestamp;
    }
    struct ValidationResponse {
        uint256 taskId;
        uint256 validatorTokenId;
        uint8 status; // 0: approved, 1: rejected, 2: requires_revision
        uint256 confidence;
        uint256 stakedAmount;
        bytes signature;
        uint256 timestamp;
    }
    uint256 public taskIdCounter;
    mapping(uint256 => TaskRequest) public tasks;
    mapping(uint256 => TaskExecution) public executions;
    mapping(uint256 => ValidationResponse[]) public validationResponses;
    mapping(uint256 => uint256) public taskRewards;
    CHATToken public chatToken;
    ERC8004ReputationRegistry public reputationRegistry;
    event TaskCreated(uint256 indexed taskId, uint256 serverAgentTokenId);
    event TaskExecuted(uint256 indexed taskId, bytes32 resultHash);
    event TaskValidated(uint256 indexed taskId, uint256 validatorTokenId);
    event TaskSettled(uint256 indexed taskId, uint256 totalReward);
    constructor(address _chatToken, address _reputationRegistry) {
        chatToken = CHATToken(_chatToken);
        reputationRegistry = ERC8004ReputationRegistry(_reputationRegistry);
        taskIdCounter = 1;
    }
    /**
     * @dev Create a new task for validation
     */
    function createTask(
        uint256 _serverAgentTokenId,
        string memory _taskDescription,
        bytes32 _dataHash,
        uint256 _deadline,
        uint256 _requiredValidations,
        uint256 _rewardAmount
    ) external onlyOwner returns (uint256) {
        uint256 taskId = taskIdCounter;
        taskIdCounter = taskIdCounter.add(1);
        TaskRequest memory task = TaskRequest({
            taskId: taskId,
            serverAgentTokenId: _serverAgentTokenId,
            validatorAgentTokenId: 0,
            taskDescription: _taskDescription,
            dataHash: _dataHash,
            deadline: _deadline,
            requiredValidations: _requiredValidations,
            rewardAmount: _rewardAmount,
            createdAt: block.timestamp,
            isComplete: false
        });
        tasks[taskId] = task;
        taskRewards[taskId] = _rewardAmount;
        emit TaskCreated(taskId, _serverAgentTokenId);
        return taskId;
    }
    /**
     * @dev Record task execution
     */
    function recordExecution(
        uint256 _taskId,
        uint256 _executionTime,
        bytes32 _resultHash,
        string memory _resultSummary,
        uint256 _confidenceScore
    ) external {
        require(tasks[_taskId].createdAt != 0, "Task not found");
        require(!tasks[_taskId].isComplete, "Task already complete");
        TaskExecution memory execution = TaskExecution({
            taskId: _taskId,
            executionTime: _executionTime,
            resultHash: _resultHash,
            resultSummary: _resultSummary,
            confidenceScore: _confidenceScore,
            timestamp: block.timestamp
        });
        executions[_taskId] = execution;
        emit TaskExecuted(_taskId, _resultHash);
    }
    /**
     * @dev Validate task execution
     */
    function validateTask(
        uint256 _taskId,
        uint256 _validatorTokenId,
        uint8 _status,
        uint256 _confidence,
        uint256 _stakedAmount
    ) external {
        require(tasks[_taskId].createdAt != 0, "Task not found");
        require(_confidence <= 100, "Confidence must be 0-100");
        ValidationResponse memory response = ValidationResponse({
            taskId: _taskId,
            validatorTokenId: _validatorTokenId,
            status: _status,
            confidence: _confidence,
            stakedAmount: _stakedAmount,
            signature: "",
            timestamp: block.timestamp
        });
        validationResponses[_taskId].push(response);
        // Check if task is fully validated
        if (validationResponses[_taskId].length >= tasks[_taskId].requiredValidations) {
            _settleTask(_taskId);
        }
        emit TaskValidated(_taskId, _validatorTokenId);
    }
    /**
     * @dev Settle task and distribute rewards
     */
    function _settleTask(uint256 _taskId) internal {
        TaskRequest storage task = tasks[_taskId];
        require(!task.isComplete, "Task already settled");
        task.isComplete = true;
        uint256 reward = taskRewards[_taskId];
        require(reward > 0, "No reward to distribute");
        // Distribute reward to server agent (70%)
        uint256 serverReward = (reward * 70) / 100;
       
        // Distribute reward to validators (30%)
        uint256 validatorReward = (reward * 30) / 100;
        uint256 perValidatorReward = validatorReward / validationResponses[_taskId].length;
        // Transfer rewards
        chatToken.transfer(msg.sender, serverReward);
       
        for (uint256 i = 0; i < validationResponses[_taskId].length; i++) {
            chatToken.transfer(msg.sender, perValidatorReward);
        }
        emit TaskSettled(_taskId, reward);
    }
    /**
     * @dev Get task details
     */
    function getTask(uint256 _taskId) external view returns (TaskRequest memory) {
        return tasks[_taskId];
    }
    /**
     * @dev Get task execution details
     */
    function getExecution(uint256 _taskId) external view returns (TaskExecution memory) {
        return executions[_taskId];
    }
    /**
     * @dev Get validation responses for task
     */
    function getValidations(uint256 _taskId)
        external
        view
        returns (ValidationResponse[] memory)
    {
        return validationResponses[_taskId];
    }
}
