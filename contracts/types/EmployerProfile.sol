
struct EmployerProfile {
    uint256 id;
    string name;
    bool isHiring;
    address wallet;
}

struct CreateJobListingProps {
    string title;
    string jobDescription;
    uint256 deadline;
    uint256 fixedPriceInWei;
}