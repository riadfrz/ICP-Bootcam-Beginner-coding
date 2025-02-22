import Result "mo:base/Result";
import Text "mo:base/Text";
import Principal "mo:base/Principal";
import Map "mo:map/Map";
import Vector "mo:vector";
import { phash; nhash } "mo:map/Map";
import Nat "mo:base/Nat";


actor {
    stable var nextId : Nat = 0;
    stable var userIdmap : Map.Map<Principal, Nat> = Map.new<Principal, Nat>();
    stable var userProfileMap : Map.Map<Nat, Text> = Map.new<Nat, Text>();
    stable var userResultsMap : Map.Map<Nat, Vector.Vector<Text>> = Map.new<Nat, Vector.Vector<Text>>();


    public query ({ caller }) func getUserProfile() : async Result.Result<{ id : Nat; name : Text }, Text> {
        let userId =
        switch (Map.get(userIdmap, phash, caller)) {
            case (?found) found;
            case (_) return #err("User not found");
        };

        let name = 
        switch (Map.get(userProfileMap, nhash, userId)) {
            case (?found) found;
            case (_) return #err("User name not found");    
        };

        return #ok({id= userId; name = name});
    };


    public shared ({ caller }) func setUserProfile(name : Text) : async Result.Result<{ id : Nat; name : Text }, Text> {
        var idRecorded = 0;
        // guardian clause to check if the user already exists
        switch (Map.get(userIdmap, phash, caller)) {
            case (?idFound) {
                Map.set(userIdmap, phash, caller, idFound);
                Map.set(userProfileMap, nhash, idFound, name);
                idRecorded := idFound;
            };
            case (_) {
                Map.set(userIdmap, phash, caller, nextId);
                Map.set(userProfileMap, nhash, nextId, name);
                nextId += 1;
            };
        };
        
        return #ok({id= idRecorded ; name = name}); 
    };

    public shared ({ caller }) func addUserResult(result : Text) : async Result.Result<{ id : Nat; results : [Text] }, Text> {
        let userId =
        switch (Map.get(userIdmap, phash, caller)) {
            case (?found) found;
            case (_) return #err("User not found");
        };

        let userResults =
        switch (Map.get(userResultsMap, nhash, userId)) {
            case (?found) found;
            case (_) Vector.new<Text>();
        };
        
        Vector.add(userResults, result);
        Map.set(userResultsMap, nhash, userId, userResults);
    
        return #ok({ id = userId; results = Vector.toArray(userResults) });
    };

    public query ({ caller }) func getUserResults() : async Result.Result<{ id : Nat; results : [Text] }, Text> {
         let userId = switch (Map.get(userIdmap, phash, caller)) {
            case (?found) found;
            case (_) return #err("User not found");
        };

        let userResults = switch (Map.get(userResultsMap, nhash, userId)) {
            case (?found) Vector.toArray(found);
            case (_) [];
        };

        return #ok({ id = userId; results = userResults });
    };
};
