<!-- Use this file to provide workspace-specific custom instructions to Copilot. For more details, visit https://code.visualstudio.com/docs/copilot/copilot-customization#_use-a-githubcopilotinstructionsmd-file -->

# Solidity Smart Contract Security Analysis Project

This project uses GitHub Copilot to generate Solidity smart contracts from prompts and automatically analyzes them using Slither static code analysis via GitHub Actions.

## Project Structure
- `contracts/` - Generated Solidity smart contracts
- `prompts/` - Text files containing prompts for contract generation
- `.github/workflows/` - GitHub Actions for automated Slither analysis
- `reports/` - Slither analysis reports

## Workflow
1. Generate Solidity contracts using GitHub Copilot from prompts
2. Push contracts to repository
3. GitHub Actions automatically runs Slither analysis
4. Results are stored in reports directory

## Copilot Instructions
- Focus on generating secure Solidity smart contracts
- Follow best practices for smart contract development
- Include comprehensive comments and documentation
- Generate contracts with various complexity levels for thorough testing

## Progress Tracking
- [x] Create workspace structure
- [ ] Set up GitHub repository
- [ ] Create GitHub Actions workflow for Slither
- [ ] Add sample contracts for testing
- [ ] Test the complete pipeline
