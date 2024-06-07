// SPDX-License-Identifier: MIT

pragma solidity >=0.8.7;

interface ICreativeController {
    function GetCreativeVersion(uint _seedNumber) external view returns (uint);
}

interface IDynamicController {
    function GetDynamicVersion(uint _seedNumber) external view returns (uint);
}

contract R00TMATRIX {

    address Owner;

    address public adminAddress;
    address public dynamicController;
    mapping (uint => address) public creativeController;
    

    constructor() {
        Owner = msg.sender;
    }

    string public arGateway = 'https://arweave.net/';
    bool public gatewayLock;

    // Mapping to keep track of active and immutable entries for each version
    // version => array of seedNumbers
    mapping(uint => uint[]) private activeEntries;
    mapping(uint => uint[]) private immutableEntries;

    mapping (uint => string) public versionData;
    mapping (uint => uint) public dynamicVersion;
    mapping (uint => bool) public lockedCreative;
    uint[] private activeVersions;
    uint public creativeCurrent = 1;
    
    struct seedDATA {
        uint length;
        uint tempo;
        uint barNumber;
        uint offset;
        uint[2] timeSig;
        string keyInfo;
        string arHash;
        string visualSuffix;
        uint[][] harmRhythm;
        bool locked;
        string[] stemNames;
    }

    mapping (uint => mapping (uint => seedDATA)) public R00T_MATRIX;

    event SeedDataSet(uint seedNumber, uint version);
    event NewActiveEntry(uint seedNumber, uint version);
    event NewActiveVersion(uint version);
    event EntryDeleted(uint seedNumber, uint version);
    event VersionNoLongerActive (uint version);
    event EntryLocked(uint seedNumber, uint version);
    event CreativeControlChange(uint _iteration, address _to, address _from);
    event DynamicControlChange(address _to, address _from);



    //Public getter functions

    //return single entry mix link

    function GetMixStatic(uint _seedNumber, uint _version, bool _includeGateway, bool _hiRes) external view returns (string memory) {
        string memory prefix = _includeGateway ? arGateway : "";
        string memory fileExtension = _hiRes ? "wav" : "mp3";
        string memory link = string(abi.encodePacked(prefix, R00T_MATRIX[_seedNumber][_version].arHash, "/mix.", fileExtension));

        return link;
    }

    // dynamic version can change from time to time but will largely point to the orginal

    function GetMixDynamic(uint _seedNumber, bool _includeGateway, bool _hiRes) external view returns (string memory) {
        string memory prefix = _includeGateway ? arGateway : "";
        string memory fileExtension = _hiRes ? "wav" : "mp3";
        string memory link = string(abi.encodePacked(prefix, R00T_MATRIX[_seedNumber][GetDynamicVersion(_seedNumber)].arHash, "/mix.", fileExtension));

        return link;
    }

    // creative version is programatically controlled and can be contrinuously dynamic

    function GetMixCreative(uint _seedNumber, bool _includeGateway, bool _hiRes) external view returns (string memory) {
        string memory prefix = _includeGateway ? arGateway : "";
        string memory fileExtension = _hiRes ? "wav" : "mp3";
        string memory link = string(abi.encodePacked(prefix, R00T_MATRIX[_seedNumber][GetCreativeVersion(_seedNumber, creativeCurrent)].arHash, "/mix.", fileExtension));

        return link;
    }

    function GetEntryStatic(uint _seedNumber, uint _version) external view returns (seedDATA memory) {
        return R00T_MATRIX[_seedNumber][_version];
    }

    function GetEntryDynamic(uint _seedNumber) external view returns (seedDATA memory) {
        return R00T_MATRIX[_seedNumber][GetDynamicVersion(_seedNumber)];
    }

    function GetEntryCreative(uint _seedNumber) external view returns (seedDATA memory) {
        return R00T_MATRIX[_seedNumber][GetCreativeVersion(_seedNumber,creativeCurrent)];
    }

    //getters for each part of the structs

    function GetLength(uint _seedNumber, uint _version) external view returns (uint) {
        return R00T_MATRIX[_seedNumber][_version].length;
    }

    function GetTempo(uint _seedNumber, uint _version) external view returns (uint) {
        return R00T_MATRIX[_seedNumber][_version].tempo;
    }

    function GetBarNumber(uint _seedNumber, uint _version) external view returns (uint) {
        return R00T_MATRIX[_seedNumber][_version].barNumber;
    }

    function GetOffset(uint _seedNumber, uint _version) external view returns (uint) {
        return R00T_MATRIX[_seedNumber][_version].offset;
    }

    function GetTimeSig(uint _seedNumber, uint _version) external view returns (uint[2] memory) {
        return R00T_MATRIX[_seedNumber][_version].timeSig;
    }

    function GetKeyInfo(uint _seedNumber, uint _version) external view returns (string memory) {
        return R00T_MATRIX[_seedNumber][_version].keyInfo;
    }

    function GetCoverArt(uint _seedNumber, uint _version, bool _includeGateway) external view returns (string memory) {
        string memory prefix = _includeGateway ? arGateway : "";
        string memory link = string(abi.encodePacked(prefix, R00T_MATRIX[_seedNumber][_version].arHash, "/visual.", R00T_MATRIX[_seedNumber][_version].visualSuffix));
        return link;
    }

    function GetHarmonicRhythm(uint _seedNumber, uint _version) external view returns (uint[][] memory) {
        return R00T_MATRIX[_seedNumber][_version].harmRhythm;
    }

    function GetLockedStatus(uint _seedNumber, uint _version) external view returns (bool) {
        return R00T_MATRIX[_seedNumber][_version].locked;
    }

    function GetStemNames(uint _seedNumber, uint _version) external view returns (string[] memory) {
        return R00T_MATRIX[_seedNumber][_version].stemNames;
    }

    // return single entry stems links

    function GetStems(uint _seedNumber, uint _version ,bool _includeGateway, bool _hiRes) external view returns (string[] memory) {
        string memory prefix = _includeGateway ? arGateway : "";
        string memory fileExtension = _hiRes ? "wav" : "mp3";
        uint length = R00T_MATRIX[_seedNumber][_version].stemNames.length;
        string[] memory temp = new string[](length);

        for(uint i = 0; i < length; i++) {
            temp[i] = string(abi.encodePacked(prefix, R00T_MATRIX[_seedNumber][_version].arHash, "/", R00T_MATRIX[_seedNumber][_version].stemNames[i], ".", fileExtension));
        }
        return temp;
    }

    function GetActiveEntriesByVersion(uint _version) external view returns (uint[] memory) {
        return activeEntries[_version];
    }

    function GetImmutableEntriesByVersion(uint _version) external view returns (uint[] memory) {
        return immutableEntries[_version];
    }

    function GetActiveVersions() external view returns (uint[] memory) {
        return activeVersions;
    }

    function lockCreative(uint _iteration) public {
        require(msg.sender == Owner || msg.sender == adminAddress, "Not authorized.");
        lockedCreative[_iteration] = true;
    }

    function GetALLActiveEntries() public view returns (uint[][] memory) {
        uint[][] memory allActiveEntries = new uint[][](activeVersions.length);

        for (uint i = 0; i < activeVersions.length; i++) {
            uint version = activeVersions[i];
            uint[] storage entries = activeEntries[version];
            allActiveEntries[i] = new uint[](entries.length);

            for (uint j = 0; j < entries.length; j++) {
                allActiveEntries[i][j] = entries[j];
            }
        }

        return allActiveEntries;
    }

    function GetALLImmutableEntries() public view returns (uint[][] memory) {
        uint[][] memory allImmutableEntries = new uint[][](activeVersions.length);

        for (uint i = 0; i < activeVersions.length; i++) {
            uint version = activeVersions[i];
            uint[] storage entries = immutableEntries[version];
            allImmutableEntries[i] = new uint[](entries.length);

            for (uint j = 0; j < entries.length; j++) {
                allImmutableEntries[i][j] = entries[j];
            }
        }

        return allImmutableEntries;
    }

    // THIS DYNAMICALLY UPDATES - return all entries  - a SEEDS and versions

    function GetActiveVersionsBySeed(uint _seedNumber) public view returns (uint[] memory) {
        uint[] memory tempVersions = new uint[](activeVersions.length);
        uint count = 0;

        // Iterate through all active versions
        for (uint i = 0; i < activeVersions.length; i++) {
            uint version = activeVersions[i];
            
            // Check if the seed number is present in the active entries of the version
            for (uint j = 0; j < activeEntries[version].length; j++) {
                if (activeEntries[version][j] == _seedNumber) {
                    tempVersions[count] = version;
                    count++;
                    break;
                }
            }
        }

        // Copy the active versions to a dynamically sized array to return
        uint[] memory activeVersionsBySeed = new uint[](count);
        for (uint i = 0; i < count; i++) {
            activeVersionsBySeed[i] = tempVersions[i];
        }

        return activeVersionsBySeed;
    }

    function GetImmutableVersionsBySeed(uint _seedNumber) public view returns (uint[] memory) {
        uint[] memory tempVersions = new uint[](activeVersions.length);
        uint count = 0;

        // Iterate through all versions in activeVersions (assuming all versions are tracked here)
        for (uint i = 0; i < activeVersions.length; i++) {
            uint version = activeVersions[i];
            
            // Check if the seed number is present in the immutable entries of the version
            for (uint j = 0; j < immutableEntries[version].length; j++) {
                if (immutableEntries[version][j] == _seedNumber) {
                    tempVersions[count] = version;
                    count++;
                    break;
                }
            }
        }

        // Copy the immutable versions to a dynamically sized array to return
        uint[] memory immutableVersionsBySeed = new uint[](count);
        for (uint i = 0; i < count; i++) {
            immutableVersionsBySeed[i] = tempVersions[i];
        }

        return immutableVersionsBySeed;
    }

    function GetCreativeVersion(uint _seedNumber, uint _iteration) public view returns (uint) {
        address controllerAddress = creativeController[_iteration];
        require(controllerAddress != address(0), "Controller not set");

        ICreativeController controller = ICreativeController(controllerAddress);
        return controller.GetCreativeVersion(_seedNumber);
    }

    function GetDynamicVersion(uint _seedNumber) public view returns (uint) {
        address controllerAddress = dynamicController;
        require(controllerAddress != address(0), "Controller not set");

        IDynamicController dynController = IDynamicController(controllerAddress);
        return dynController.GetDynamicVersion(_seedNumber);
    }

    //Set functions - Owner / admin only

    function setEntry (uint _seedNumber, uint _version, uint _Length, uint _Tempo, uint _BarNumber, uint _Offset, uint[2] memory _TimeSig, string memory _KeyInfo, string memory _ArHash, string memory _visualSuffix, uint[][] memory _HarmRhy) public {
        
        require(msg.sender == Owner || msg.sender == adminAddress, "Not authorized.");
        require(R00T_MATRIX[_seedNumber][_version].locked == false, "Entry is locked for immutability.");
        
        R00T_MATRIX[_seedNumber][_version].length = _Length;
        R00T_MATRIX[_seedNumber][_version].tempo = _Tempo;
        R00T_MATRIX[_seedNumber][_version].barNumber = _BarNumber;
        R00T_MATRIX[_seedNumber][_version].offset = _Offset;
        R00T_MATRIX[_seedNumber][_version].timeSig = _TimeSig;
        R00T_MATRIX[_seedNumber][_version].keyInfo = _KeyInfo;
        R00T_MATRIX[_seedNumber][_version].arHash = _ArHash;
        R00T_MATRIX[_seedNumber][_version].visualSuffix = _visualSuffix;
        R00T_MATRIX[_seedNumber][_version].harmRhythm = _HarmRhy;

        // If the version is not in the array, add it
        if (!versionExists(_version)) {
            activeVersions.push(_version);
            emit NewActiveVersion(_version);
        }

        // If the entry is not in the array, add it
        if (!entryExists(_seedNumber, _version)) {
            activeEntries[_version].push(_seedNumber);
            emit NewActiveEntry(_seedNumber, _version);
        }

        emit SeedDataSet(_seedNumber, _version);
    }

    function entryExists(uint _seedNumber, uint _version) public view returns (bool) {
        bool eDoesExist = false;
        for (uint i = 0; i < activeEntries[_version].length; i++) {
            if (activeEntries[_version][i] == _seedNumber) {
                eDoesExist = true;
                break;
            }
        }
        return eDoesExist;
    }

    function versionExists(uint _version) private view returns (bool) {
        bool vDoesExist = false;
        for (uint i = 0; i < activeVersions.length; i++) {
            if (activeVersions[i] == _version) {
                vDoesExist = true;
                break;
            }
        }
        return vDoesExist;
    }

    function deleteEntry (uint _seedNumber, uint _version) public {
        require(msg.sender == Owner, "Not authorized.");
        require(entryExists(_seedNumber, _version), "Entry doesn't exist yet.");
        require(R00T_MATRIX[_seedNumber][_version].locked == false, "Entry is locked for immutability.");

        // "Delete" the data by setting it to default values
        delete R00T_MATRIX[_seedNumber][_version];

        // Remove the entry from activeEntries
        for (uint i = 0; i < activeEntries[_version].length; i++) {
            if (activeEntries[_version][i] == _seedNumber) {
                activeEntries[_version][i] = activeEntries[_version][activeEntries[_version].length - 1];
                activeEntries[_version].pop();
                emit EntryDeleted(_seedNumber, _version);
                break;
            }
        }

        // If no more active entries exist for this version, remove the version from activeVersions
        if (activeEntries[_version].length == 0) {
            for (uint i = 0; i < activeVersions.length; i++) {
                if (activeVersions[i] == _version) {
                    activeVersions[i] = activeVersions[activeVersions.length - 1];
                    activeVersions.pop();
                    emit VersionNoLongerActive(_version);
                    break;
                }
            }
        }
    }

    function lockEntry (uint _seedNumber, uint _version) public {
        require(msg.sender == Owner, "Not authorized.");
        require(entryExists(_seedNumber, _version), "Entry doesn't exist yet.");
        R00T_MATRIX[_seedNumber][_version].locked = true;

        immutableEntries[_version].push(_seedNumber);
        emit EntryLocked(_seedNumber, _version);
    }

    function lockGateway() public {
        require(msg.sender == Owner, "Not authorized.");
        require(!gatewayLock, "Already locked.");
        gatewayLock = true;
    }

    function setAdmin(address _newAdmin) public {
        require(msg.sender == Owner, "Not authorized.");
        adminAddress = _newAdmin;
    }

    // set address/contract that will control the creative matrix

    function setCreativeController(uint _iteration, address _newCreative) public {
        require(msg.sender == Owner || msg.sender == adminAddress, "Not authorized.");
        emit CreativeControlChange(_iteration, _newCreative, creativeController[_iteration]);
        creativeController[_iteration] = _newCreative;
    }

    function setDynamicController (address _newController) public {
        require(msg.sender == Owner || msg.sender == adminAddress, "Not authorized.");
        emit DynamicControlChange(_newController, dynamicController);
        dynamicController = _newController;
    }

    function setStemNames (uint _version, uint _seedNumber, string[] memory _stemNames) public {
        require(msg.sender == Owner || msg.sender == adminAddress, "Not authorized.");
        require(R00T_MATRIX[_seedNumber][_version].locked == false, "Entry is locked for immutability.");
        delete R00T_MATRIX[_seedNumber][_version].stemNames;
        for(uint i = 0; i < _stemNames.length; i++) {
            R00T_MATRIX[_seedNumber][_version].stemNames.push(_stemNames[i]);
        }
    }

    function setGateway (string memory _gateway) public {
        require(msg.sender == Owner || msg.sender == adminAddress, "Not authorized.");
        require(!gatewayLock, "Gateway is locked.");
        arGateway = _gateway;
    }

    function setVersionData(uint _version, string memory _info) public {
        require(msg.sender == Owner || msg.sender == adminAddress, "Not authorized.");
        
        versionData[_version] = _info;
    }

    // set the current version that Creative reads will recieve

    function setCreativeCurrent(uint _newCreative) public {
        require(msg.sender == Owner || msg.sender == adminAddress, "Not authorized.");
        creativeCurrent = _newCreative;
    }

    function changeOwner (address _newOwner) public {
        require(msg.sender == Owner, "Not authorized.");
        Owner = _newOwner;
    }
    
    // Array to store addresses of extension contracts
    mapping(address => string) private xExtensionDetails;
    address[] private xExtensionKeys;
    mapping(address => bool) private xImmutableKeys;
    mapping(address => bool) private xActiveKeys;

    // Function to add an extension contract with its details
    function xAddExtensionContract(address _contract, string memory _details) public {
        require(msg.sender == Owner, "Not authorized.");
        require(!xActiveKeys[_contract], "Extension is already added.");

        xExtensionDetails[_contract] = _details;
        xActiveKeys[_contract] = true;
        xExtensionKeys.push(_contract);
    }

    function xSetExtensionDetails(address _contract, string memory _details) public {
        require(msg.sender == Owner, "Not authorized.");
        require(!xImmutableKeys[_contract], "Extension is immutable.");
        xExtensionDetails[_contract] = _details;
    }

    // Function to lock an extension contract, making it immutable
    function xLockExtensionContract(address _contract) public {
        require(msg.sender == Owner, "Not authorized.");
        require(xActiveKeys[_contract], "Extension does not exist.");
        
        xImmutableKeys[_contract] = true;
    }

    // Function to remove an extension contract
    function xRemoveExtensionContract(address _contract) public {
        require(msg.sender == Owner, "Not authorized.");
        require(!xImmutableKeys[_contract], "Extension is immutable.");

        for (uint i = 0; i < xExtensionKeys.length; i++) {
            if (xExtensionKeys[i] == _contract) {
                xExtensionKeys[i] = 0x000000000000000000000000000000000000dEaD;
                break;
            }
        }
        
        xActiveKeys[_contract] = false;
        delete xExtensionDetails[_contract];
    }

    // Define a struct to hold the address and description together
    struct ExtensionInfo {
        address addr;
        string description;
    }

    // Function to return a list of active extensions coupled with their descriptions
    function xGetActiveExtensions() public view returns (ExtensionInfo[] memory) {
        uint activeCount = 0;
        // First, count the active extensions
        for (uint i = 0; i < xExtensionKeys.length; i++) {
            if (xActiveKeys[xExtensionKeys[i]]) {
                activeCount++;
            }
        }

        // Initialize the array of structs with the count of active extensions
        ExtensionInfo[] memory activeExtensions = new ExtensionInfo[](activeCount);

        uint counter = 0;
        // Populate the array with active extension details
        for (uint i = 0; i < xExtensionKeys.length; i++) {
            if (xActiveKeys[xExtensionKeys[i]]) {
                ExtensionInfo memory info = ExtensionInfo({
                    addr: xExtensionKeys[i],
                    description: xExtensionDetails[xExtensionKeys[i]]
                });
                activeExtensions[counter] = info;
                counter++;
            }
        }

        return activeExtensions;
    }

    // Function to return a list of immutable extension contract addresses
    function xGetImmutableExtensions() public view returns (ExtensionInfo[] memory) {
        uint immutableCount = 0;
        // First, count the number of immutable extensions
        for (uint i = 0; i < xExtensionKeys.length; i++) {
            if (xImmutableKeys[xExtensionKeys[i]]) {
                immutableCount++;
            }
        }

        // Initialize the array with the count of immutable extensions
        ExtensionInfo[] memory immutableExtensions = new ExtensionInfo[](immutableCount);

        uint counter = 0;
        // Populate the array with immutable extension addresses
        for (uint i = 0; i < xExtensionKeys.length; i++) {
            if (xImmutableKeys[xExtensionKeys[i]]) {
                ExtensionInfo memory info = ExtensionInfo({
                    addr: xExtensionKeys[i],
                    description: xExtensionDetails[xExtensionKeys[i]]
                });
                immutableExtensions[counter] = info;
                counter++;
            }
        }

        return immutableExtensions;
    }
}
